import SwiftUI
import AVFoundation

struct TrainingView: View {
    @ObservedObject var model: MetronomeModel
    @ObservedObject var audioEngine = AudioEngine()
    @State private var showResults = false
    @State private var feedback = ""
    @State private var feedbackColor = Color.gray
    
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
            ProgressView(value: model.progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.bottom)
            
            HStack {
                Text("Прошло: \(formatTime(model.elapsedTime))")
                Spacer()
                Text("Осталось: \(formatTime(model.duration - model.elapsedTime))")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Spacer()
            
            Circle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 200, height: 200)
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 4)
                )
                .overlay(
                    Text("\(model.currentBeat + 1)/\(model.totalBeats)")
                        .font(.title)
                        .foregroundColor(.white)
                )
                .scaleEffect(model.currentBeat % 4 == 0 ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: model.currentBeat)
            
            Text(feedback)
                .font(.headline)
                .foregroundColor(feedbackColor)
                .padding()
                .animation(.easeInOut(duration: 0.2), value: feedback)
            
            Spacer()
            
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
                VStack {
                    MicrophoneLevelView(level: audioEngine.audioLevel * 10)
                        .frame(height: 100)
                        .padding(.bottom, 30)
                    
                    Text("Микрофон активен")
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                model.stopMetronome()
                if model.mode == .microphone {
                    audioEngine.stopMonitoring()
                }
                showResults = true
            }) {
                Text("Завершить тренировку")
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
        model.handleTap()
        
        let timeSinceLastBeat = model.elapsedTime.truncatingRemainder(dividingBy: model.beatInterval)
        let timeToNextBeat = model.beatInterval - timeSinceLastBeat
        
        let timeDifference = min(timeSinceLastBeat, timeToNextBeat)
        
        if timeDifference < model.perfectHitThreshold {
            feedback = "Идеально!"
            feedbackColor = .green
        } else if timeDifference < model.goodHitThreshold {
            feedback = "Хорошо!"
            feedbackColor = .blue
        } else {
            feedback = "Мимо"
            feedbackColor = .orange
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            feedback = ""
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

struct MicrophoneLevelView: View {
    var level: Double
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<20, id: \.self) { index in
                Rectangle()
                    .fill(barColor(for: index))
                    .frame(width: 10)
                    .frame(height: barHeight(for: index))
                    .cornerRadius(5)
            }
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
