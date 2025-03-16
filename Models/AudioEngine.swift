import Foundation
import AVFoundation
import Accelerate

class AudioEngine: NSObject, ObservableObject {
    // Аудио параметры
    @Published var audioLevel: Double = 0.0
    @Published var isBeatDetected: Bool = false

    // Данные для визуализации
    @Published var recentAudioLevels: [Double] = Array(repeating: 0.0, count: 100)

    // Внутренние переменные для обработки аудио
    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var isMonitoring: Bool = false
    private var lastBeatTime: Date?
    private var minimumTimeBetweenBeats: TimeInterval = 0.1
    private var lastMetronomeClickTime: Date?
    private var metronomeClickGracePeriod: TimeInterval = 0.05

    // Функция для наблюдателей обнаружения звука
    var onAudioDetected: ((Double) -> Void)?

    // Порог срабатывания для обнаружения удара
    private let beatThreshold: Float = 0.2
    private let minimumAudioLevel: Float = 0.01

    // Буфер для сглаживания значений аудио
    private var audioLevelsBuffer: [Double] = []
    private let smoothingFactor = 5

    override init() {
        super.init()
        // Подготовка буфера для сглаживания звука
        audioLevelsBuffer = Array(repeating: 0.0, count: smoothingFactor)
    }

    func startMonitoring() throws {
        guard !isMonitoring else { return }

        // Настраиваем аудио сессию
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Подготавливаем временный файл для записи
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let url = URL(fileURLWithPath: documentsPath).appendingPathComponent("temp_audio.wav")

        // Настройки записи с высоким качеством и быстрой реакцией
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        // Создаем рекордер
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.isMeteringEnabled = true

            // Запускаем запись
            if audioRecorder?.record() == true {
                isMonitoring = true

                // Запускаем таймер для проверки уровня аудио
                levelTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
                    self?.checkAudioLevel()
                }
                print("Мониторинг аудио запущен")
            } else {
                throw NSError(domain: "AudioEngineErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось запустить запись аудио"])
            }
        } catch {
            throw error
        }
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        // Останавливаем таймер и запись
        levelTimer?.invalidate()
        levelTimer = nil

        audioRecorder?.stop()
        audioRecorder = nil

        isMonitoring = false
        print("Мониторинг аудио остановлен")

        // Сбрасываем состояние
        audioLevel = 0.0
        isBeatDetected = false
        lastBeatTime = nil

        // Освобождаем аудио сессию с задержкой
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Ошибка при деактивации аудио сессии: \(error)")
            }
        }
    }

    // Метод для уведомления о клике метронома (чтобы избежать ложных срабатываний)
    func notifyMetronomeClick() {
        lastMetronomeClickTime = Date()
    }

    private func checkAudioLevel() {
        guard isMonitoring, let recorder = audioRecorder else { return }

        recorder.updateMeters()

        // Получаем уровень звука (в децибелах)
        let avgPower = recorder.averagePower(forChannel: 0)
        _ = recorder.peakPower(forChannel: 0)

        // Проверяем, не близко ли это к клику метронома
        if let lastClickTime = lastMetronomeClickTime,
           Date().timeIntervalSince(lastClickTime) < metronomeClickGracePeriod {
            // Игнорируем звуки, близкие к кликам метронома
            return
        }

        // Преобразуем децибелы в линейную шкалу (0-1)
        let linearLevel = pow(10.0, avgPower / 20.0)

        // Нормализуем уровень звука до диапазона 0-1
        let normalizedLevel = min(max(0.0, Double(linearLevel) * 5.0), 1.0)

        // Сглаживаем значения для более стабильного отображения
        audioLevelsBuffer.removeFirst()
        audioLevelsBuffer.append(normalizedLevel)

        // Применяем скользящее среднее
        let smoothedLevel = audioLevelsBuffer.reduce(0.0, +) / Double(audioLevelsBuffer.count)

        // Обновляем публикуемое значение уровня аудио
        audioLevel = smoothedLevel

        // Добавляем значение в массив для визуализации
        recentAudioLevels.removeFirst()
        recentAudioLevels.append(smoothedLevel)

        // Проверяем на резкий скачок громкости, указывающий на удар
        let isBeat = linearLevel > beatThreshold &&
                    (lastBeatTime == nil ||
                     Date().timeIntervalSince(lastBeatTime!) > minimumTimeBetweenBeats)

        if isBeat {
            // Обновляем время последнего удара
            lastBeatTime = Date()
            isBeatDetected = true

            // Вызываем обработчик события
            if linearLevel > minimumAudioLevel {
                onAudioDetected?(Double(linearLevel))
            }

            // Сбрасываем флаг обнаружения удара через короткий промежуток
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.isBeatDetected = false
            }
        }
    }
}