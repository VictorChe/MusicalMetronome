import Foundation
import AVFoundation

class MetronomeModel: ObservableObject {
    // Настройки метронома
    @Published var tempo: Double = 90
    @Published var duration: Double = 20
    @Published var mode: TrainingMode = .tap

    // Состояние метронома
    @Published var isRunning = false
    @Published var isCountdown = false
    @Published var countdownCount = 4
    @Published var currentBeat = 0
    @Published var elapsedTime: Double = 0

    // Результаты
    @Published var perfectHits = 0
    @Published var goodHits = 0
    @Published var missedHits = 0
    @Published var skippedBeats = 0

    // Аудио
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var startTime: Date?

    let goodHitThreshold = 0.1
    let perfectHitThreshold = 0.05

    var beatInterval: TimeInterval {
        60.0 / tempo
    }

    var totalBeats: Int {
        Int(duration * tempo / 60.0)
    }

    var progress: Double {
        if isRunning {
            return min(elapsedTime / duration, 1.0)
        } else {
            return 0
        }
    }

    enum TrainingMode: String, CaseIterable, Identifiable {
        case tap = "Тапы"
        case microphone = "Микрофон"

        var id: String { self.rawValue }
    }

    init() {
        setupAudio()
    }

    func resetResults() {
        perfectHits = 0
        goodHits = 0
        missedHits = 0
        skippedBeats = 0
        currentBeat = 0
        elapsedTime = 0
    }

    private func setupAudio() {
        do {
            print("Начало настройки аудио")
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("Аудио сессия настроена")

            // Проверяем пути к ресурсам
            if let resourcePath = Bundle.main.resourcePath {
                print("Путь к ресурсам: \(resourcePath)")
            }

            // Проверяем наличие звукового файла
            if let soundURL = Bundle.main.url(forResource: "metronome-click", withExtension: "wav") {
                print("Найден звуковой файл: \(soundURL)")
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                updateClickVolume()
                print("Аудио плеер успешно настроен")
            } else {
                print("ОШИБКА: Не удалось найти файл metronome-click.wav")
                // Попробуем найти все .wav файлы в бандле
                let wavFiles = Bundle.main.urls(forResourcesWithExtension: "wav", subdirectory: nil)
                print("Доступные .wav файлы: \(wavFiles ?? [])")
            }
        } catch {
            print("ОШИБКА настройки аудио: \(error.localizedDescription)")
        }
    }

    private func updateClickVolume() {
        // В режиме микрофона устанавливаем тихий звук клика
        audioPlayer?.volume = mode == .microphone ? 0.3 : 1.0
        print("Установлена громкость клика: \(audioPlayer?.volume ?? 0)")
    }

    func startMetronome() {
        resetResults()
        isCountdown = true
        countdownCount = 4
        currentBeat = 0
        updateClickVolume()
        playTick()

        timer = Timer.scheduledTimer(withTimeInterval: beatInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.isCountdown {
                self.countdownCount -= 1
                if self.countdownCount > 0 {
                    self.playTick()
                } else {
                    self.isCountdown = false
                    self.isRunning = true
                    self.startTime = Date()
                    self.playTick()
                }
            } else if self.isRunning {
                if let startTime = self.startTime {
                    self.elapsedTime = Date().timeIntervalSince(startTime)
                }
                self.currentBeat += 1
                self.playTick()
                if self.currentBeat >= self.totalBeats {
                    self.stopMetronome()
                }
            }
        }
    }

    func stopMetronome() {
        print("Остановка метронома")
        isRunning = false
        isCountdown = false
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func playTick() {
        guard let audioPlayer = audioPlayer else {
            print("Ошибка: audioPlayer не инициализирован")
            return
        }

        print("Воспроизведение клика: режим=\(mode), громкость=\(audioPlayer.volume)")

        if audioPlayer.isPlaying {
            audioPlayer.stop()
        }
        audioPlayer.currentTime = 0
        audioPlayer.play()
    }

    func handleTap() {
        guard isRunning else { return }
        let timeSinceLastBeat = elapsedTime.truncatingRemainder(dividingBy: beatInterval)
        let timeToNextBeat = beatInterval - timeSinceLastBeat
        let timeDifference = min(timeSinceLastBeat, timeToNextBeat)

        if timeDifference < perfectHitThreshold {
            perfectHits += 1
        } else if timeDifference < goodHitThreshold {
            goodHits += 1
        } else {
            missedHits += 1
        }
    }

    func handleAudioInput(intensity: Double) {
        guard isRunning else { return }
        let timeSinceLastBeat = elapsedTime.truncatingRemainder(dividingBy: beatInterval)
        let timeToNextBeat = beatInterval - timeSinceLastBeat
        let timeDifference = min(timeSinceLastBeat, timeToNextBeat)

        if timeDifference < perfectHitThreshold {
            perfectHits += 1
        } else if timeDifference < goodHitThreshold {
            goodHits += 1
        } else {
            missedHits += 1
        }
    }

    func calculateSkippedBeats() {
        let totalHits = perfectHits + goodHits + missedHits
        skippedBeats = totalBeats - totalHits
        if skippedBeats < 0 { skippedBeats = 0 }
    }
}