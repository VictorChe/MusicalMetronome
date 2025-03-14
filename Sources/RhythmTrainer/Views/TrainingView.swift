import SwiftUI
import AVFoundation

struct TrainingView: View {
    @ObservedObject var model: MetronomeModel
    @ObservedObject var audioEngine = AudioEngine()
    @State private var showResults = false
    @State private var feedback = ""
    @State private var feedbackColor = Color.gray
    @State private var showFeedback = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Group {
                            if model.isCountdown {
                                countdownView
                            } else if model.isRunning {
                                trainingView
                            } else {
                                finishedView
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
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

    private var countdownView: some View {
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
                .padding(.horizontal)
        }
    }

    private var trainingView: some View {
        VStack(spacing: 20) {
            // Прогресс
            ProgressView(value: model.progress)
                .progressViewStyle(LinearProgressViewStyle())

            // Время
            HStack {
                Text("Прошло: \(formatTime(model.elapsedTime))")
                Spacer()
                Text("Осталось: \(formatTime(model.duration - model.elapsedTime))")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            // Статистика
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.green)
                    Text("Идеальные")
                    Spacer()
                    Text("\(model.perfectHits)")
                        .font(.headline)
                }

                HStack {
                    Image(systemName: "star")
                        .foregroundColor(.blue)
                    Text("Хорошие")
                    Spacer()
                    Text("\(model.goodHits)")
                        .font(.headline)
                }

                HStack {
                    Image(systemName: "star.slash")
                        .foregroundColor(.orange)
                    Text("Неточные")
                    Spacer()
                    Text("\(model.missedHits)")
                        .font(.headline)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)

            Spacer()

            // Индикатор бита
            Circle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 200, height: 200)
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 4)
                )
                .overlay(
                    VStack {
                        Text("\(model.currentBeat + 1)")
                            .font(.system(size: 48, weight: .bold))
                        Text("из \(model.totalBeats)")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                )
                .scaleEffect(model.currentBeat % 4 == 0 ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: model.currentBeat)

            // Обратная связь
            if !feedback.isEmpty {
                Text(feedback)
                    .font(.title2)
                    .foregroundColor(feedbackColor)
                    .opacity(showFeedback ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showFeedback)
            }

            Spacer()

            // Элементы управления
            if model.mode == .tap {
                Button {
                    handleUserAction(intensity: 1.0)
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
                AudioLevelView(level: audioEngine.audioLevel * 10)
                    .frame(height: 100)
                    .padding(.vertical)
            }

            // Кнопка завершения
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
                .padding(10)
            }
        }
    }

    private var finishedView: some View {
        VStack(spacing: 30) {
            Text("Тренировка завершена!")
                .font(.title)
                .fontWeight(.bold)

            Button {
                showResults = true
            } label: {
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
            audioEngine.onAudioDetected = { [weak self] intensity in
                self?.handleUserAction(intensity: intensity)
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

struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingView(model: MetronomeModel())
    }
}