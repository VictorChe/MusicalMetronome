import SwiftUI

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
            .fullScreenCover(isPresented: $showResults) {
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

                if showFeedback {
                    Text(feedback)
                        .foregroundColor(feedbackColor)
                        .padding()
                        .background(feedbackColor.opacity(0.1))
                        .cornerRadius(10)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: showFeedback)
                }

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

            Button {
                showResults = true
            } label: {
                Text("Посмотреть результаты")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            Button {
                dismiss()
            } label: {
                Text("Вернуться в меню")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
    }

    func setupAudioEngine() {
        if model.mode == .microphone {
            // Устанавливаем двустороннюю связь между моделью и аудио-движком
            model.audioEngine = audioEngine

            audioEngine.startMonitoring()
            audioEngine.onAudioDetected = { intensity in
                handleUserAction()
            }
        }
    }

    func handleUserAction() {
        if model.mode == .tap {
            model.handleTap()
        } else if model.mode == .microphone {
            // Используем метод обработки аудио вместо обычного тапа
            model.handleAudioInput(intensity: audioEngine.audioLevel)
        }

        // Обратная связь для пользователя
        showFeedbackMessage()
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