import Foundation
import AVFoundation

class MetronomeModel: ObservableObject {
    // Настройки метронома
    @Published var tempo: Double = 90 // BPM (от 60 до 120)
    @Published var duration: Double = 20 // Длительность в секундах (от 10 до 30)
    @Published var mode: TrainingMode = .tap // Режим тренировки

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
    @Published var extraHits = 0 // Добавлен счетчик лишних нот

    // Аудио
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var startTime: Date?

    // Базовые значения для темпа 60 BPM
    private let basePerfectThreshold = 0.05 // 50ms
    private let baseGoodThreshold = 0.15 // 150ms

    // Динамические пороги в зависимости от темпа
    var perfectHitThreshold: Double {
        basePerfectThreshold * (60 / tempo)
    }

    var goodHitThreshold: Double {
        baseGoodThreshold * (60 / tempo)
    }

    // Защита от множественных попаданий
    private var lastHitBeat: Int = -1
    private var lastHitTime: TimeInterval = 0
    private let minimumTimeBetweenHits: TimeInterval = 0.05

    // Отслеживание попаданий для каждого бита
    private var beatHits: [Int: Int] = [:]

    // Расчетные значения
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
        extraHits = 0
        currentBeat = 0
        elapsedTime = 0
        beatHits = [:]
        lastHitBeat = -1
        lastHitTime = 0
    }

    private func setupAudio() {
        // Загрузка звука метронома
        if let soundURL = Bundle.main.url(forResource: "metronome-click", withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Не удалось загрузить звук: \(error.localizedDescription)")
            }
        }
    }

    func startMetronome() {
        resetResults()
        isCountdown = true
        countdownCount = 4
        currentBeat = 0

        // Начинаем обратный отсчет
        playTick()

        timer = Timer.scheduledTimer(withTimeInterval: beatInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.isCountdown {
                self.countdownCount -= 1
                if self.countdownCount > 0 {
                    self.playTick()
                } else {
                    // Обратный отсчет закончен, начинаем тренировку
                    self.isCountdown = false
                    self.isRunning = true
                    self.startTime = Date()
                    self.playTick()
                }
            } else if self.isRunning {
                // Обновляем прошедшее время
                if let startTime = self.startTime {
                    self.elapsedTime = Date().timeIntervalSince(startTime)
                }

                self.currentBeat += 1
                self.playTick()

                // Проверяем, закончилась ли тренировка
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

    // Функция вызывается, когда пользователь тапает
    func handleTap() {
        guard isRunning else { return }

        let currentTime = Date().timeIntervalSince1970
        let currentBeatNumber = Int(elapsedTime / beatInterval)
        let timeSinceLastBeat = elapsedTime.truncatingRemainder(dividingBy: beatInterval)
        let timeToNextBeat = beatInterval - timeSinceLastBeat
        let timeDifference = min(timeSinceLastBeat, timeToNextBeat)

        // Проверяем минимальный интервал между попаданиями
        if currentTime - lastHitTime < minimumTimeBetweenHits {
            extraHits += 1
            print("Лишняя нота (слишком быстрое нажатие)")
            return
        }

        // Находим ближайший бит к текущему времени
        let nearestBeatNumber = Int(round(elapsedTime / beatInterval))
        let distanceToBeat = abs(elapsedTime - Double(nearestBeatNumber) * beatInterval)

        // Проверяем, не было ли уже попадания на этот бит
        if nearestBeatNumber == lastHitBeat {
            extraHits += 1
            print("Лишняя нота (повторное попадание)")
            return
        }

        lastHitTime = currentTime
        lastHitBeat = nearestBeatNumber

        // Нормализуем отклонение относительно темпа
        let normalizedDeviation = distanceToBeat / beatInterval

        // Определяем тип попадания с учетом темпа
        if normalizedDeviation < perfectHitThreshold {
            perfectHits += 1
            print("Идеальное попадание (отклонение: \(Int(normalizedDeviation * 100))%)")
        } else if normalizedDeviation < goodHitThreshold {
            goodHits += 1
            print("Хорошее попадание (отклонение: \(Int(normalizedDeviation * 100))%)")
        } else if normalizedDeviation < 0.25 { // Максимальное отклонение 25% от интервала
            missedHits += 1
            print("Неточное попадание (отклонение: \(Int(normalizedDeviation * 100))%)")
        } else {
            extraHits += 1
            print("Нота мимо (отклонение: \(Int(normalizedDeviation * 100))%)")
        }

        print("Статистика - Идеальные: \(perfectHits), Хорошие: \(goodHits), Неточные: \(missedHits), Мимо: \(extraHits)")
    }

    // Функция вызывается, когда обнаружен звук от микрофона
    func handleAudioInput(intensity: Double) {
        guard isRunning else { return }

        // Похожая логика как и в handleTap
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

    // Оценка пропущенных битов (вызывать при завершении)
    func calculateSkippedBeats() {
        let totalHits = perfectHits + goodHits + missedHits
        skippedBeats = totalBeats - totalHits
        if skippedBeats < 0 {
            skippedBeats = 0
        }
    }
}