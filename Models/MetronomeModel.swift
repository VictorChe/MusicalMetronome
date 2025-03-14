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
    @Published var extraHits = 0

    // Аудио
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var startTime: Date?

    // Пороги для попаданий (в долях от интервала между битами)
    private let perfectThresholdRatio = 0.05 // 5% от интервала для идеальных попаданий
    private let goodThresholdRatio = 0.15 // 15% от интервала для хороших попаданий
    private let poorThresholdRatio = 0.3 // 30% от интервала для неточных попаданий

    // Защита от множественных попаданий
    private var lastHitBeat: Int = -1
    private var lastHitTime: TimeInterval = 0
    private var minimumTimeBetweenHits: TimeInterval { beatInterval * 0.25 } // 25% от интервала

    var beatInterval: TimeInterval {
        60.0 / tempo
    }

    var totalBeats: Int {
        Int(duration * tempo / 60.0)
    }

    var progress: Double {
        guard let startTime = startTime else { return 0 }
        return min(Date().timeIntervalSince(startTime) / duration, 1.0)
    }

    enum TrainingMode: String, CaseIterable, Identifiable {
        case tap = "Тапы"
        case microphone = "Микрофон"
        var id: String { self.rawValue }
    }

    init() {
        setupAudio()
    }

    private func setupAudio() {
        if let soundURL = Bundle.main.url(forResource: "metronome-click", withExtension: "wav") {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Ошибка настройки аудио: \(error)")
            }
        }
    }

    func resetResults() {
        perfectHits = 0
        goodHits = 0
        missedHits = 0
        skippedBeats = 0
        extraHits = 0
        currentBeat = 0
        elapsedTime = 0
        lastHitBeat = -1
        lastHitTime = 0
        startTime = nil
    }

    func startMetronome() {
        resetResults()
        isCountdown = true
        countdownCount = 4

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
        isRunning = false
        isCountdown = false
        timer?.invalidate()
        timer = nil
        calculateSkippedBeats()
    }

    private func playTick() {
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }

    func handleTap() {
        guard isRunning else { return }

        let currentTime = Date().timeIntervalSince1970
        
        // Получаем текущее время с момента начала
        guard let startTime = startTime else { return }
        let actualElapsed = Date().timeIntervalSince(startTime)
        
        // Рассчитываем, на каком мы сейчас бите и каково отклонение
        let exactBeatPosition = actualElapsed / beatInterval  // Точная позиция в битах
        let nearestBeatNumber = round(exactBeatPosition)      // Ближайший целый бит
        
        // Отклонение в долях бита (от 0 до 0.5)
        let beatDeviation = abs(exactBeatPosition - nearestBeatNumber)
        // Отклонение в секундах
        let timeDeviation = beatDeviation * beatInterval
        
        print("Точная позиция: \(exactBeatPosition), Ближайший бит: \(nearestBeatNumber), Отклонение в долях: \(beatDeviation), Отклонение в секундах: \(timeDeviation)")

        // Проверяем минимальный интервал между нажатиями
        if currentTime - lastHitTime < minimumTimeBetweenHits {
            extraHits += 1
            print("Слишком частое нажатие")
            return
        }

        // Проверяем, не было ли уже попадания на этот бит
        if Int(nearestBeatNumber) == lastHitBeat {
            extraHits += 1
            print("Повторное нажатие на тот же бит")
            return
        }

        lastHitTime = currentTime
        lastHitBeat = Int(nearestBeatNumber)

        // Определяем тип попадания на основе отклонения в долях
        print("Отклонение в долях бита: \(beatDeviation)")

        // Используем абсолютное значение отклонения для определения типа попадания
        if beatDeviation <= perfectThresholdRatio {
            perfectHits += 1
            print("Идеальное попадание: \(beatDeviation)")
        } else if beatDeviation <= goodThresholdRatio {
            goodHits += 1
            print("Хорошее попадание: \(beatDeviation)")
        } else if beatDeviation <= poorThresholdRatio {
            missedHits += 1
            print("Неточное попадание: \(beatDeviation)")
        } else {
            extraHits += 1
            print("Нота мимо: \(beatDeviation)")
        }

        print("Статистика - Идеальные: \(perfectHits), Хорошие: \(goodHits), Неточные: \(missedHits), Мимо: \(extraHits)")
    }

    func handleAudioInput(intensity: Double) {
        guard isRunning else { return }
        
        let currentTime = Date().timeIntervalSince1970
        
        // Полностью убираем порог интенсивности
        print("Обнаружен аудиосигнал с интенсивностью: \(intensity)")
        
        // Получаем текущее время с момента начала
        guard let startTime = startTime else { 
            print("Ошибка: startTime не установлено")
            return 
        }
        
        // Вычисляем задержку обработки аудио (примерно 50-100 мс)
        let audioProcessingDelay = 0.075 // 75 мс - ориентировочная задержка захвата и обработки аудио
        
        // Корректируем фактическое время с учетом задержки обработки аудио
        let actualElapsed = Date().timeIntervalSince(startTime) - audioProcessingDelay
        
        // Рассчитываем, на каком мы сейчас бите и каково отклонение
        let exactBeatPosition = actualElapsed / beatInterval
        let nearestBeatNumber = round(exactBeatPosition)
        
        // Отклонение в долях бита (от 0 до 0.5)
        let beatDeviation = abs(exactBeatPosition - nearestBeatNumber)
        
        // Значительно увеличиваем допустимое отклонение для режима микрофона
        let microAdjustment = 3.0 // Увеличиваем пороги в 3 раза
        
        // Проверяем минимальный интервал между нажатиями 
        // Ещё больше уменьшаем интервал для режима микрофона
        if currentTime - lastHitTime < (minimumTimeBetweenHits * 0.5) {
            print("Слишком частое обнаружение звука: пропущено \(currentTime - lastHitTime)s")
            return
        }
        
        // Проверяем, не было ли уже попадания на этот бит
        if Int(nearestBeatNumber) == lastHitBeat {
            print("Повторное обнаружение звука на тот же бит: \(nearestBeatNumber)")
            return
        }
        
        lastHitTime = currentTime
        lastHitBeat = Int(nearestBeatNumber)
        
        // Определяем тип попадания с учетом сильно увеличенных порогов для микрофона
        print("Отклонение в долях бита: \(beatDeviation)")
        
        // Для режима микрофона сильно увеличиваем пороги
        let adjustedPerfectThreshold = perfectThresholdRatio * microAdjustment
        let adjustedGoodThreshold = goodThresholdRatio * microAdjustment 
        let adjustedPoorThreshold = poorThresholdRatio * microAdjustment
        
        // Печатаем подробную отладочную информацию
        print("Оригинальные пороги - Идеальное: \(perfectThresholdRatio), Хорошее: \(goodThresholdRatio), Неточное: \(poorThresholdRatio)")
        print("Скорректированные пороги - Идеальное: \(adjustedPerfectThreshold), Хорошее: \(adjustedGoodThreshold), Неточное: \(adjustedPoorThreshold)")
        
        if beatDeviation <= adjustedPerfectThreshold {
            perfectHits += 1
            print("Идеальное попадание: \(beatDeviation) (порог: \(adjustedPerfectThreshold))")
        } else if beatDeviation <= adjustedGoodThreshold {
            goodHits += 1
            print("Хорошее попадание: \(beatDeviation) (порог: \(adjustedGoodThreshold))")
        } else if beatDeviation <= adjustedPoorThreshold {
            missedHits += 1
            print("Неточное попадание: \(beatDeviation) (порог: \(adjustedPoorThreshold))")
        } else {
            extraHits += 1
            print("Нота мимо: \(beatDeviation) (выше порога: \(adjustedPoorThreshold))")
        }
        
        print("Статистика - Идеальные: \(perfectHits), Хорошие: \(goodHits), Неточные: \(missedHits), Мимо: \(extraHits)")
    }

    func calculateSkippedBeats() {
        let totalHits = perfectHits + goodHits + missedHits
        skippedBeats = max(0, totalBeats - totalHits)
    }
}