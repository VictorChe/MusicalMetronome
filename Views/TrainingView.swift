import SwiftUI
import AVFoundation

struct TrainingView: View {
    @ObservedObject var model: MetronomeModel
    @ObservedObject var audioEngine = AudioEngine()
    @Environment(\.dismiss) private var dismiss
    @State private var showResults = false
    @State private var feedback = ""
    @State private var feedbackColor = Color.gray
    @State private var showFeedback = false

    var body: some View {
        GeometryReader { _ in
            VStack {
                if model.isCountdown {
                    countdownView
                } else if model.isRunning {
                    trainingView
                } else {
                    finishedView
                }
            }
            .padding()
            .onAppear {
                setupAudioEngine()
            }
            .onDisappear {
                if model.mode == .microphone {
                    audioEngine.stopMonitoring()
                }
            }
            .navigationBarBackButtonHidden(model.isRunning || model.isCountdown)
            .fullScreenCover(isPresented: $showResults, onDismiss: {
                // Проверяем, завершена ли тренировка
                if !model.isRunning && !model.isCountdown {
                    // Если завершена, возвращаемся на главный экран
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }
            }) {
                ResultsView(model: model)
            }
        }
    }

    var countdownView: some View {
        VStack(spacing: 30) {
            Text("Приготовьтесь...")
                .font(.title)
                .fontWeight(.bold)

            Text("\(model.countdownCount)")
                .font(.system(size: 120, weight: .bold))
                .foregroundColor(.blue)
                .frame(height: 150)
                .animation(.easeInOut(duration: 0.5), value: model.countdownCount)

            Text("Темп: \(Int(model.tempo)) BPM")
                .font(.title2)

            Text(model.mode == .tap ? "Нажимайте на кнопку в ритм" : "Играйте в ритм метронома")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
        }
    }

    var trainingView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProgressView(value: model.progress)
                    .progressViewStyle(LinearProgressViewStyle())

                HStack {
                    Text("Прошло: \(formatTime(model.elapsedTime))")
                    Spacer()
                    Text("Осталось: \(formatTime(model.duration - model.elapsedTime))")
                }

                Text("Бит: \(model.currentBeat) / \(model.totalBeats)")
                    .font(.headline)

                VStack(spacing: 10) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 20, height: 20)
                        Text("Идеальные: \(model.perfectHits)")
                    }

                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                        Text("Хорошие: \(model.goodHits)")
                    }

                    HStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 20, height: 20)
                        Text("Неточные: \(model.missedHits)")
                    }

                    HStack {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 20, height: 20)
                        Text("Мимо: \(model.extraHits)")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // Контейнер с фиксированной высотой для отображения обратной связи
                ZStack {
                    if showFeedback {
                        Text(feedback)
                            .foregroundColor(feedbackColor)
                            .padding()
                            .background(feedbackColor.opacity(0.1))
                            .cornerRadius(10)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: showFeedback)
                    }
                }
                .frame(height: 50) // Фиксированная высота блока с обратной связью

                if model.mode == .tap {
                    Button {
                        handleUserAction()
                    } label: {
                        Text("Тап")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 150, height: 150)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.vertical)
                } else {
                    AudioLevelView(level: audioEngine.audioLevel)
                        .frame(height: 100)
                        .padding(.vertical)
                }

                Button(role: .destructive) {
                    model.stopMetronome()
                    if model.mode == .microphone {
                        audioEngine.stopMonitoring()
                    }
                    showResults = true
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Завершить тренировку")
                    }
                    .padding()
                }
            }
            .padding()
        }
    }

    var finishedView: some View {
        VStack(spacing: 30) {
            Text("Тренировка завершена!")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            // Автоматически показываем результаты после небольшой задержки
            Text("Загрузка результатов...")
                .onAppear {
                    // Небольшая задержка для анимации
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showResults = true
                    }
                }
        }
    }

    private func setupAudioEngine() {
        if model.mode == .microphone {
            // Обеспечиваем связь между метрономом и аудио движком
            model.audioEngine = audioEngine

            // Запускаем мониторинг аудио с задержкой после настройки метронома
            // Это предотвратит конфликты аудио сессий
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }

                // Запускаем мониторинг аудио
                self.audioEngine.startMonitoring()

                // Устанавливаем обработчик обнаружения звука
                self.audioEngine.onAudioDetected = { [weak self] intensity in
                    guard let self = self else { return }
                    self.handleUserAction()
                }

                print("Мониторинг аудио успешно запущен")
            }
        }
    }

    func handleUserAction() {
        let previousPerfectHits = model.perfectHits
        let previousGoodHits = model.goodHits
        let previousMissedHits = model.missedHits
        let previousExtraHits = model.extraHits

        if model.mode == .tap {
            model.handleTap()
        } else if model.mode == .microphone {
            // Используем метод обработки аудио вместо обычного тапа
            model.handleAudioInput(intensity: audioEngine.audioLevel)
        }

        // Обратная связь для пользователя на основе последнего нажатия
        if model.extraHits > previousExtraHits {
            feedback = "Мимо"
            feedbackColor = .purple
        } else if model.perfectHits > previousPerfectHits {
            feedback = "Идеально!"
            feedbackColor = .green
        } else if model.goodHits > previousGoodHits {
            feedback = "Хорошо!"
            feedbackColor = .blue
        } else if model.missedHits > previousMissedHits {
            feedback = "Неточно"
            feedbackColor = .orange
        }

        showFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showFeedback = false
        }
    }

    func showFeedbackMessage() {
        let totalHits = model.perfectHits + model.goodHits + model.missedHits

        if totalHits > 0 {
            let lastHitType: String
            let lastHitColor: Color

            if model.perfectHits > 0 && model.perfectHits > model.goodHits && model.perfectHits > model.missedHits {
                lastHitType = "Идеально!"
                lastHitColor = .green
            } else if model.goodHits > 0 && model.goodHits > model.missedHits {
                lastHitType = "Хорошо!"
                lastHitColor = .blue
            } else if model.missedHits > 0 {
                lastHitType = "Неточно!"
                lastHitColor = .orange
            } else {
                lastHitType = "Мимо!"
                lastHitColor = .red
            }

            feedback = lastHitType
            feedbackColor = lastHitColor
            showFeedback = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showFeedback = false
            }
        }
    }

    func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}