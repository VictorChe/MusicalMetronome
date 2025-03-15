
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
    @State private var showStopConfirmation = false
    @State private var lastUpdatedPatternIndex: Int = -1

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
                showResults = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !model.isRunning && !model.isCountdown {
                        // Инициализация случайных паттернов при начале тренировки
                        model.initializeRandomPatterns()
                        model.startMetronome()
                    }
                    setupAudioEngine()
                }
            }
            .onDisappear {
                if model.mode == .microphone {
                    audioEngine.stopMonitoring()
                }
            }
            .navigationBarBackButtonHidden(model.isRunning || model.isCountdown)
            .fullScreenCover(isPresented: $showResults, onDismiss: {
                if !model.isRunning && !model.isCountdown {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                } else {
                    showResults = false
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
                
                // Добавление ритмических фигур
                RhythmPatternsView(model: model, onPatternTapped: { index in
                    // При нажатии на паттерн, можно добавить дополнительную логику,
                    // например, воспроизведение звука паттерна
                })
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                
                // Вызов обновления паттерна, если изменился текущий бит
                // и мы должны обновить паттерн
                .onChange(of: model.currentBeat) { oldBeat, newBeat in
                    // Обновляем случайный паттерн каждые 4 бита или если это первый бит
                    if newBeat > 0 && (newBeat % 4 == 0 || lastUpdatedPatternIndex == -1) {
                        let randomIndex = Int.random(in: 0..<model.currentPatterns.count)
                        lastUpdatedPatternIndex = randomIndex
                        model.updateRandomPattern(at: randomIndex)
                    }
                }

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
                .frame(height: 50)

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
                    VStack(spacing: 5) {
                        Text("Уровень звука: \(Int(audioEngine.audioLevel * 100))%")
                            .font(.caption)
                            .foregroundColor(audioEngine.isBeatDetected ? .green : .gray)
                        
                        // Улучшенная спектограмма
                        AudioLevelView(
                            level: audioEngine.audioLevel,
                            isBeatDetected: audioEngine.isBeatDetected,
                            showWaveform: model.mode == .microphone,
                            beats: Array(1...model.totalBeats).map { Double($0) },
                            currentBeatPosition: Double(model.currentBeat),
                            userHits: getUserHits()
                        )
                        .frame(height: 80)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                        
                        // Индикатор обнаружения звука
                        HStack(spacing: 10) {
                            Circle()
                                .fill(audioEngine.isBeatDetected ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                                .animation(.easeInOut(duration: 0.2), value: audioEngine.isBeatDetected)
                            
                            Text(audioEngine.isBeatDetected ? "Звук обнаружен!" : "Ожидание звука...")
                                .font(.caption)
                                .foregroundColor(audioEngine.isBeatDetected ? .green : .gray)
                        }
                    }
                    .padding(.vertical)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(10)
                }

                Button(role: .destructive) {
                    showStopConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Завершить тренировку")
                    }
                    .padding()
                }
                .confirmationDialog(
                    "Остановить тренировку?",
                    isPresented: $showStopConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Остановить", role: .destructive) {
                        model.stopMetronome()
                        if model.mode == .microphone {
                            audioEngine.stopMonitoring()
                        }
                        showResults = true
                    }
                    Button("Продолжить", role: .cancel) { }
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

            Text("Загрузка результатов...")
                .onAppear {
                    if !model.isRunning && !model.isCountdown && !showResults {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            showResults = true
                        }
                    }
                }
        }
    }

    private func setupAudioEngine() {
        if model.mode == .microphone {
            model.audioEngine = audioEngine
            model.viewCallback = {
                self.handleUserAction()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                do {
                    try self.audioEngine.startMonitoring()
                    self.audioEngine.onAudioDetected = { intensity in
                        self.handleUserAction()
                    }
                    print("Мониторинг аудио успешно запущен")
                } catch {
                    print("Ошибка при запуске мониторинга аудио: \(error.localizedDescription)")
                }
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
            model.handleAudioInput(intensity: audioEngine.audioLevel)
        }

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
    
    // Функция для получения информации о попаданиях пользователя для визуализации
    func getUserHits() -> [(time: Double, accuracy: Double)] {
        // В реальном коде здесь будут данные о фактических попаданиях пользователя
        // Для примера создаем тестовые данные на основе статистики
        var hits: [(time: Double, accuracy: Double)] = []
        
        // Идеальные попадания (с малым отклонением)
        for _ in 0..<model.perfectHits {
            let time = Double.random(in: 1...Double(model.currentBeat))
            let accuracy = Double.random(in: 0...0.05)
            hits.append((time: time, accuracy: accuracy))
        }
        
        // Хорошие попадания (с средним отклонением)
        for _ in 0..<model.goodHits {
            let time = Double.random(in: 1...Double(model.currentBeat))
            let accuracy = Double.random(in: 0.05...0.15)
            hits.append((time: time, accuracy: accuracy))
        }
        
        // Неточные попадания (с большим отклонением)
        for _ in 0..<model.missedHits {
            let time = Double.random(in: 1...Double(model.currentBeat))
            let accuracy = Double.random(in: 0.15...0.3)
            hits.append((time: time, accuracy: accuracy))
        }
        
        // В будущем здесь будут реальные данные из модели метронома
        return hits
    }
}
