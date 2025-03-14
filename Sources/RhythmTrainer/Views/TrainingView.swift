
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
            .fullScreenCover(isPresented: $showResults) {
                ResultsView(model: model)
            }
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
                .padding()
        }
    }

    private var trainingView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProgressView(value: model.progress)
                    .progressViewStyle(LinearProgressViewStyle())

                HStack {
                    Text("Прошло: \(formatTime(model.elapsedTime))")
                    Spacer()
                    Text("Осталось: \(formatTime(model.duration - model.elapsedTime))")
                }
                .font(.caption)
                .foregroundColor(.secondary)

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

                if !feedback.isEmpty {
                    Text(feedback)
                        .font(.title2)
                        .foregroundColor(feedbackColor)
                        .opacity(showFeedback ? 1 : 0)
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
            audioEngine.startMonitoring()
        }
    }

    private func handleUserAction() {
        let previousPerfectHits = model.perfectHits
        let previousGoodHits = model.goodHits
        let previousMissedHits = model.missedHits
        
        if model.mode == .tap {
            model.handleTap()
        } else {
            model.handleAudioInput(intensity: audioEngine.audioLevel)
        }
        
        if model.perfectHits > previousPerfectHits {
            feedback = "Идеально!"
            feedbackColor = .green
        } else if model.goodHits > previousGoodHits {
            feedback = "Хорошо!"
            feedbackColor = .blue
        } else if model.missedHits > previousMissedHits {
            feedback = "Мимо"
            feedbackColor = .orange
        }
        
        showFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showFeedback = false
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
