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

    // Временные окна для попаданий
    let goodHitThreshold = 0.15 // 150ms для хороших попаданий
    let perfectHitThreshold = 0.05 // 50ms для идеальных попаданий

    // Защита от множественных попаданий
    private var lastHitBeat: Int = -1
    private var lastHitTime: TimeInterval = 0
    private let minimumTimeBetweenHits: TimeInterval = 0.1

    var beatInterval: TimeInterval {
        60.0 / tempo
    }

    var totalBeats: Int {
        Int(duration * tempo / 60.0)
    }

    var progress: Double {
        guard let startTime = startTime else { return 0 }
        let actualElapsed = Date().timeIntervalSince(startTime)
        return min(actualElapsed / duration, 1.0)
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
        print("Сброс результатов тренировки")
        perfectHits = 0
        goodHits = 0
        missedHits = 0
        skippedBeats = 0
        currentBeat = 0
        elapsedTime = 0
        lastHitBeat = -1
        lastHitTime = 0
        startTime = nil
    }

    private func setupAudio() {
        do {
            print("Начало настройки аудио")
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("Аудио сессия настроена")

            if let soundURL = Bundle.main.url(forResource: "metronome-click", withExtension: "wav") {
                print("Найден звуковой файл: \(soundURL)")
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                updateClickVolume()
                print("Аудио плеер успешно настроен")
            } else {
                print("ОШИБКА: Не удалось найти файл metronome-click.wav")
            }
        } catch {
            print("ОШИБКА настройки аудио: \(error.localizedDescription)")
        }
    }

    private func updateClickVolume() {
        audioPlayer?.volume = mode == .microphone ? 0.3 : 1.0
        print("Установлена громкость клика: \(audioPlayer?.volume ?? 0)")
    }

    func startMetronome() {
        print("Запуск метронома")
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
                    print("Начало тренировки")
                }
            } else if self.isRunning {
                if let startTime = self.startTime {
                    self.elapsedTime = Date().timeIntervalSince(startTime)
                }
                self.currentBeat += 1
                self.playTick()

                print("Текущий бит: \(self.currentBeat)/\(self.totalBeats)")

                if self.currentBeat >= self.totalBeats {
                    print("Достигнуто максимальное количество битов")
                    self.stopMetronome()
                }
            }
        }
    }

    func stopMetronome() {
        print("Остановка метронома")
        print("Итоговая статистика - Идеальные: \(perfectHits), Хорошие: \(goodHits), Неточные: \(missedHits)")
        isRunning = false
        isCountdown = false
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        startTime = nil
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

    private func calculateHitAccuracy() -> (beatNumber: Int, timeDifference: TimeInterval) {
        guard let startTime = startTime else {
            return (-1, .infinity)
        }

        let actualElapsed = Date().timeIntervalSince(startTime)
        let currentBeatNumber = Int(actualElapsed / beatInterval)
        let timeSinceLastBeat = actualElapsed.truncatingRemainder(dividingBy: beatInterval)
        let timeToNextBeat = beatInterval - timeSinceLastBeat
        let timeDifference = min(timeSinceLastBeat, timeToNextBeat)

        return (currentBeatNumber, timeDifference)
    }

    func handleTap() {
        guard isRunning else { return }

        let currentTime = Date().timeIntervalSince1970
        let (currentBeatNumber, timeDifference) = calculateHitAccuracy()

        print("""
            Обработка тапа:
            - Текущий бит: \(currentBeatNumber)
            - Последний бит с попаданием: \(lastHitBeat)
            - Время с последнего попадания: \(currentTime - lastHitTime)
            - Разница во времени: \(timeDifference)
            """)

        // Проверяем минимальный интервал между попаданиями
        if currentTime - lastHitTime < minimumTimeBetweenHits {
            print("Игнорируем слишком частые попадания")
            return
        }

        // Проверяем, не было ли уже попадания на этот бит
        if currentBeatNumber == lastHitBeat {
            print("Игнорируем повторное попадание на бит \(currentBeatNumber)")
            return
        }

        lastHitTime = currentTime
        lastHitBeat = currentBeatNumber

        // Определяем тип попадания и обновляем статистику
        if timeDifference < perfectHitThreshold {
            perfectHits += 1
            print("Идеальное попадание на бит \(currentBeatNumber)")
        } else if timeDifference < goodHitThreshold {
            goodHits += 1
            print("Хорошее попадание на бит \(currentBeatNumber)")
        } else {
            missedHits += 1
            print("Неточное попадание на бит \(currentBeatNumber)")
        }

        print("Текущая статистика - Идеальные: \(perfectHits), Хорошие: \(goodHits), Неточные: \(missedHits)")
    }

    func handleAudioInput(intensity: Double) {
        guard isRunning else { return }

        let currentTime = Date().timeIntervalSince1970
        let (currentBeatNumber, timeDifference) = calculateHitAccuracy()

        print("""
            Обработка аудио входа:
            - Интенсивность: \(intensity)
            - Текущий бит: \(currentBeatNumber)
            - Последний бит с попаданием: \(lastHitBeat)
            - Время с последнего попадания: \(currentTime - lastHitTime)
            - Разница во времени: \(timeDifference)
            """)

        // Проверяем минимальный интервал между попаданиями
        if currentTime - lastHitTime < minimumTimeBetweenHits {
            print("Игнорируем слишком частые попадания")
            return
        }

        // Проверяем, не было ли уже попадания на этот бит
        if currentBeatNumber == lastHitBeat {
            print("Игнорируем повторное попадание на бит \(currentBeatNumber)")
            return
        }

        lastHitTime = currentTime
        lastHitBeat = currentBeatNumber

        // Определяем тип попадания и обновляем статистику
        if timeDifference < perfectHitThreshold {
            perfectHits += 1
            print("Идеальное попадание на бит \(currentBeatNumber)")
        } else if timeDifference < goodHitThreshold {
            goodHits += 1
            print("Хорошее попадание на бит \(currentBeatNumber)")
        } else {
            missedHits += 1
            print("Неточное попадание на бит \(currentBeatNumber)")
        }

        print("Текущая статистика - Идеальные: \(perfectHits), Хорошие: \(goodHits), Неточные: \(missedHits)")
    }

    func calculateSkippedBeats() {
        let totalHits = perfectHits + goodHits + missedHits
        skippedBeats = totalBeats - totalHits
        if skippedBeats < 0 { skippedBeats = 0 }

        print("""
            Подсчет пропущенных битов:
            - Всего битов: \(totalBeats)
            - Всего попаданий: \(totalHits)
            - Пропущено: \(skippedBeats)
            """)
    }
}