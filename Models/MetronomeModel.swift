import Foundation
import AVFoundation

class MetronomeModel: ObservableObject {
    // Настройки метронома
    @Published var tempo: Double = 90
    @Published var duration: Double = 20
    @Published var mode: TrainingMode = .tap

    // Компенсация задержки (в миллисекундах)
    @Published var latencyCompensation: Double = 0 // Стандартное значение

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
                // Настраиваем сессию для совместимости с аудио движком
                let options: AVAudioSession.CategoryOptions = [.mixWithOthers, .allowBluetooth, .defaultToSpeaker]
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: options)
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)

                // Создаем и подготавливаем аудио плеер
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.volume = 1.0

                // Устанавливаем аудио плеер для одновременного воспроизведения нескольких звуков
                audioPlayer?.numberOfLoops = 0
                audioPlayer?.enableRate = false
            } catch {
                print("Ошибка настройки аудио для метронома: \(error)")
            }
        } else {
            print("Ошибка: аудио файл метронома не найден")
        }
    }

    // Полная очистка ресурсов метронома
    func cleanupResources() {
        // Останавливаем таймер
        timer?.invalidate()
        timer = nil

        // Останавливаем аудио плеер
        audioPlayer?.stop()

        // Освобождаем аудио плеер, но не деактивируем сессию полностью,
        // чтобы избежать конфликтов при быстром переключении между экранами
        audioPlayer = nil

        // Пересоздаем аудио плеер с небольшой задержкой
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setupAudio()
        }

        print("Ресурсы метронома очищены")
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
        isRunning = false
        isCountdown = false

        // Очищаем ресурсы аудио для предотвращения дублирования звука
        cleanupResources()
    }

    func startMetronome() {
        // Проверяем, не запущена ли уже тренировка, чтобы избежать дублирования
        guard !isRunning && !isCountdown else {
            print("Тренировка уже запущена, игнорируем повторный запуск")
            return
        }

        // Убедимся, что ресурсы чистые перед началом
        cleanupResources()

        // Полностью сбрасываем все результаты
        resetResults()
        isCountdown = true
        countdownCount = 4

        // Проверяем состояние аудио плеера
        if audioPlayer == nil {
            print("Настраиваем аудио перед началом тренировки")
            setupAudio()
        }

        // Воспроизводим первый тик
        playTick()

        // Настраиваем основной таймер метронома
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

        print("Метроном успешно запущен")
    }

    func stopMetronome() {
        isRunning = false
        isCountdown = false
        timer?.invalidate()
        timer = nil
        calculateSkippedBeats()

        // Очищаем состояние аудио после завершения
        audioPlayer?.stop()
        lastDetectedAudioTime = nil

        print("Метроном остановлен, тренировка завершена")

        // Освобождаем связь с аудиодвижком, не останавливая его работу
        // Это предотвратит проблемы с повторным запуском
        let engine = audioEngine
        audioEngine = nil

        // Останавливаем мониторинг в отдельном потоке после небольшой задержки
        // чтобы избежать блокировки UI и конфликтов аудио сессии
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.2) {
            engine?.stopMonitoring()
        }
    }

    // Ссылка на аудио-движок для уведомления о кликах
    var audioEngine: AudioEngine?

    private func playTick() {
        // Проверяем, что аудио плеер существует
        guard let player = audioPlayer else {
            print("Плеер не инициализирован, пересоздаем")
            setupAudio()
            return
        }

        // Останавливаем звук, если он воспроизводится
        if player.isPlaying {
            player.stop()
        }

        // Сбрасываем позицию воспроизведения и запускаем звук
        player.currentTime = 0

        // Воспроизводим с проверкой ошибок
        if !player.play() {
            print("Ошибка воспроизведения звука метронома")

            // Пробуем пересоздать аудио плеер
            setupAudio()
            audioPlayer?.play()
        }

        // Уведомляем аудио-движок о клике метронома для фильтрации эха
        if let audioEngine = audioEngine {
            audioEngine.notifyMetronomeClick()
        }
    }

    var viewCallback: (() -> Void)?

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
        viewCallback?()
    }

    // Пороги для частоты обнаружения попаданий
    private var lastDetectedAudioTime: Date?
    private let minimumAudioDetectionInterval: TimeInterval = 0.15 // 150 мс

    // Максимальное число "мимо" за тренировку для предотвращения ложных срабатываний
    private let maxExtraHitsPerTraining = 30

    func handleAudioInput(intensity: Double) {
        guard isRunning else { return }

        let currentTime = Date().timeIntervalSince1970

        // Компенсация системной задержки
        let systemLatency = 0.02 // 20ms базовая системная задержка
        // Убрана неиспользуемая переменная

        // Получаем текущее время с момента начала
        guard let startTime = startTime else {
            print("Ошибка: startTime не установлено")
            return
        }

        // Защита от слишком частых аудио событий
        if let lastAudioTime = lastDetectedAudioTime,
           Date().timeIntervalSince(lastAudioTime) < minimumAudioDetectionInterval {
            print("Игнорирование слишком частого аудиособытия")
            return
        }

        // Устанавливаем время последнего аудиособытия
        lastDetectedAudioTime = Date()

        // Ограничиваем максимальное количество нот "мимо" за тренировку
        if extraHits >= maxExtraHitsPerTraining {
            print("Достигнуто максимальное количество нот 'мимо', дальнейшие игнорируются")
            return
        }

        // Задержка обработки аудио плюс настраиваемая пользователем компенсация задержки
        let baseDelay = 0.075 // 75 мс - базовая задержка обработки аудио
        let userLatencyCompensation = latencyCompensation / 1000.0 // переводим из мс в секунды
        let totalDelay = baseDelay + userLatencyCompensation

        // Корректируем фактическое время с учетом общей задержки
        let actualElapsed = Date().timeIntervalSince(startTime) - totalDelay

        print("Применяемая задержка: \(totalDelay) сек (базовая: \(baseDelay) + пользовательская: \(userLatencyCompensation))")

        // Рассчитываем, на каком мы сейчас бите и каково отклонение
        let exactBeatPosition = actualElapsed / beatInterval
        let nearestBeatNumber = round(exactBeatPosition)

        // Отклонение в долях бита (от 0 до 0.5)
        let beatDeviation = abs(exactBeatPosition - nearestBeatNumber)

        // Значительно увеличиваем допустимое отклонение для режима микрофона
        let microAdjustment = 2.5 // Немного уменьшаем увеличение порогов

        // Если прошло совсем мало времени с последнего звука, это явно множественное нажатие
        if currentTime - lastHitTime < (minimumTimeBetweenHits * 0.5) {
            print("Обнаружен множественный звук в течение короткого времени: \(currentTime - lastHitTime)c")
            return // Полностью игнорируем слишком частые срабатывания
        }

        // Если это тот же бит, что и раньше, но прошло немного больше времени
        if Int(nearestBeatNumber) == lastHitBeat && currentTime - lastHitTime < beatInterval * 0.7 {
            print("Обнаружен множественный звук для бита \(nearestBeatNumber)")
            return // Игнорируем множественные нажатия на том же бите
        }

        // Проверка на нахождение в допустимом диапазоне битов
        if nearestBeatNumber < 1 || nearestBeatNumber > Double(totalBeats) {
            print("Бит \(nearestBeatNumber) вне допустимого диапазона 1-\(totalBeats)")
            return // Игнорируем события до начала или после окончания тренировки
        }

        // Основная логика определения попадания
        lastHitTime = currentTime
        lastHitBeat = Int(nearestBeatNumber)

        // Определяем тип попадания с учетом сильно увеличенных порогов для микрофона
        print("Отклонение в долях бита: \(beatDeviation)")

        // Для режима микрофона увеличиваем пороги
        let adjustedPerfectThreshold = perfectThresholdRatio * microAdjustment
        let adjustedGoodThreshold = goodThresholdRatio * microAdjustment
        let adjustedPoorThreshold = poorThresholdRatio * microAdjustment

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
        viewCallback?()
    }

    func calculateSkippedBeats() {
        let totalHits = perfectHits + goodHits + missedHits
        skippedBeats = max(0, totalBeats - totalHits)
    }
}