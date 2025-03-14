import SwiftUI
import AVFoundation

struct TrainingView: View {
    @ObservedObject var model: MetronomeModel
    @ObservedObject var audioEngine = AudioEngine()
    @State private var showResults = false
    @State private var feedback = ""
    @State private var feedbackColor = Color.gray
    @State private var showFeedback = false

    var body: some View {
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
        VStack {
            // Прогресс и время
            VStack(spacing: 4) {
                ProgressView(value: model.progress)
                    .progressViewStyle(LinearProgressViewStyle())

                HStack {
                    Text("Прошло: \(formatTime(model.elapsedTime))")
                    Spacer()
                    Text("Осталось: \(formatTime(model.duration - model.elapsedTime))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.bottom)

            // Счетчики попаданий
            VStack(spacing: 8) {
                HStack {
                    Label("Идеальные", systemImage: "star.fill")
                        .foregroundColor(.green)
                    Spacer()
                    Text("\(model.perfectHits)")
                        .font(.headline)
                }

                HStack {
                    Label("Хорошие", systemImage: "star")
                        .foregroundColor(.blue)
                    Spacer()
                    Text("\(model.goodHits)")
                        .font(.headline)
                }

                HStack {
                    Label("Неточные", systemImage: "star.slash")
                        .foregroundColor(.orange)
                    Spacer()
                    Text("\(model.missedHits)")
                        .font(.headline)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)

            Spacer()

            // Визуальный метроном
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 4)
                    )

                VStack {
                    Text("\(model.currentBeat + 1)")
                        .font(.system(size: 48, weight: .bold))
                    Text("из \(model.totalBeats)")
                        .font(.headline)
                }
                .foregroundColor(.white)
            }
            .scaleEffect(model.currentBeat % 4 == 0 ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: model.currentBeat)

            // Обратная связь
            Text(feedback)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(feedbackColor)
                .opacity(showFeedback ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showFeedback)
                .padding()

            Spacer()

            // Элементы управления в зависимости от режима
            if model.mode == .tap {
                Button(action: {
                    handleUserAction(intensity: 1.0)
                }) {
                    Text("Тап")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 150, height: 150)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(.bottom, 30)
            } else {
                MicrophoneLevelView(level: audioEngine.audioLevel * 10)
                    .frame(height: 100)
                    .padding(.bottom, 30)
            }

            // Кнопка завершения
            Button(action: {
                model.stopMetronome()
                if model.mode == .microphone {
                    audioEngine.stopMonitoring()
                }
                showResults = true
            }) {
                Label("Завершить тренировку", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }

    var finishedView: some View {
        VStack(spacing: 30) {
            Text("Тренировка завершена!")
                .font(.title)
                .fontWeight(.bold)

            Button(action: {
                showResults = true
            }) {
                Text("Показать результаты")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }

    private func setupAudioEngine() {
        if model.mode == .microphone {
            audioEngine.onAudioDetected = { intensity in
                handleUserAction(intensity: intensity)
            }
            audioEngine.startMonitoring()
        }
    }

    private func handleUserAction(intensity: Double) {
        let previousPerfectHits = model.perfectHits
        let previousGoodHits = model.goodHits
        let previousMissedHits = model.missedHits

        if model.mode == .microphone {
            model.handleAudioInput(intensity: intensity)
        } else {
            model.handleTap()
        }

        // Определяем тип попадания по изменению счетчиков
        if model.perfectHits > previousPerfectHits {
            showFeedback(message: "Идеально! ⭐️", color: .green)
        } else if model.goodHits > previousGoodHits {
            showFeedback(message: "Хорошо! 👍", color: .blue)
        } else if model.missedHits > previousMissedHits {
            showFeedback(message: "Мимо 😕", color: .orange)
        }
    }

    private func showFeedback(message: String, color: Color) {
        feedback = message
        feedbackColor = color
        showFeedback = true

        // Скрываем обратную связь через некоторое время
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showFeedback = false
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// Представление для визуализации уровня микрофона
struct MicrophoneLevelView: View {
    var level: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<20, id: \.self) { index in
                    Rectangle()
                        .fill(barColor(for: index))
                        .frame(width: 10)
                        .frame(height: barHeight(for: index))
                        .cornerRadius(5)
                }
            }

            Text("Микрофон активен")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: Double = 20.0
        let maxHeight: Double = 100.0

        let threshold = Double(index) * 0.2
        let scaledLevel = min(max(0, level - threshold) * 2, 1)

        return baseHeight + (maxHeight - baseHeight) * scaledLevel
    }

    private func barColor(for index: Int) -> Color {
        let threshold = Double(index) * 0.2

        if level > threshold + 0.8 {
            return .red
        } else if level > threshold + 0.5 {
            return .orange
        } else if level > threshold {
            return .green
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}