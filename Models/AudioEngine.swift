import Foundation
import AVFoundation
import Accelerate

class AudioEngine: NSObject, ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var isMonitoring = false
    private var permissionGranted = false

    @Published var audioLevel: Double = 0
    @Published var isBeatDetected = false

    private var previousAudioLevels: [Double] = []
    private let beatDetectionThreshold: Double = 0.15

    // FFT analysis
    private let fftSetup: FFTSetup?
    private let log2n: Int = 12
    private let n: Int
    private let bufferSize: Int = 2048
    private var dominantFrequencies: [Double] = []

    var onAudioDetected: ((Double) -> Void)?

    override init() {
        n = 1 << log2n
        fftSetup = vDSP_create_fftsetup(UInt(log2n), FFTRadix(kFFTRadix2))
        super.init()
        requestPermission()
    }

    deinit {
        stopMonitoring()
        if let fftSetup = fftSetup {
            vDSP_destroy_fftsetup(fftSetup)
        }
    }

    func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if granted {
                    self?.setupAudioEngine()
                }
            }
        }
    }

    private func setupAudioEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioEngine = AVAudioEngine()
            inputNode = audioEngine?.inputNode

            guard let inputNode = inputNode else { return }

            let inputFormat = inputNode.outputFormat(forBus: 0)
            let recordingFormat = AVAudioFormat(
                standardFormatWithSampleRate: inputFormat.sampleRate,
                channels: 1
            )

            guard let recordingFormat = recordingFormat else { return }

            inputNode.installTap(onBus: 0, bufferSize: UInt32(bufferSize), format: recordingFormat) { [weak self] (buffer, when) in
                self?.processAudioBuffer(buffer)
            }

            audioEngine?.prepare()
        } catch {
            print("Error setting up audio engine: \(error.localizedDescription)")
        }
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        // Запрашиваем разрешение на доступ к микрофону
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self, granted else {
                print("Нет разрешения на доступ к микрофону")
                return
            }

            self.permissionGranted = true
            DispatchQueue.main.async {
                self.setupAndStartAudioEngine()
            }
        }
    }

    private func setupAndStartAudioEngine() {
        guard let audioEngine = audioEngine else {
            setupAudioEngine()
            startMonitoring()
            return
        }

        do {
            // Конфигурируем аудио сессию с минимальными настройками
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            // Очищаем буфер предыдущих уровней
            previousAudioLevels.removeAll()

            audioEngine.prepare()
            try audioEngine.start()

            isMonitoring = true
            print("Аудио мониторинг успешно запущен")
        } catch {
            print("Ошибка при запуске аудио мониторинга: \(error.localizedDescription)")
        }
    }

    func stopMonitoring() {
        guard isMonitoring, let audioEngine = audioEngine else { return }

        inputNode?.removeTap(onBus: 0)
        audioEngine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)

        isMonitoring = false
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        var sum: Float = 0
        vDSP_maxmgv(channelData, 1, &sum, vDSP_Length(frameLength))

        performFFT(on: channelData, frameCount: frameLength)

        let currentLevel = Double(sum)
        DispatchQueue.main.async {
            self.audioLevel = currentLevel

            self.previousAudioLevels.append(currentLevel)
            if self.previousAudioLevels.count > 5 {
                self.previousAudioLevels.removeFirst()
            }

            self.detectBeat(currentLevel: currentLevel)
        }
    }

    private func detectBeat(currentLevel: Double) {
        guard previousAudioLevels.count > 2 else { return }

        // Проверяем, не является ли сигнал эхом метронома
        if isLikelyMetronomeEcho() {
            print("Игнорирование вероятного эха метронома")
            return
        }

        // Снизим порог обнаружения до минимума
        let previousAverage = previousAudioLevels.dropLast().reduce(0, +) / Double(previousAudioLevels.count - 1)

        // Почти полностью уберем порог, чтобы отлавливать даже незначительные изменения
        let adjustedThreshold = beatDetectionThreshold * 0.1

        // Еще сильнее снизим порог минимальной громкости
        let isVolumeSpike = currentLevel > previousAverage + adjustedThreshold
        let isLoudEnough = currentLevel > 0.02 // Предельно низкий порог громкости

        // Выводим подробную отладочную информацию
        print("Аудио уровень: \(currentLevel), средний: \(previousAverage), порог: \(adjustedThreshold)")

        // Оптимизируем время обнаружения, чтобы минимизировать задержку
        if isVolumeSpike || isLoudEnough {
            print("ОБНАРУЖЕН БИТ: уровень=\(currentLevel), порог=\(previousAverage + adjustedThreshold)")
            isBeatDetected = true

            // Немедленно уведомляем о событии
            DispatchQueue.main.async {
                self.onAudioDetected?(currentLevel)
            }

            // Сокращаем время "тишины" после обнаружения звука
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isBeatDetected = false
            }
        }
    }

    // Расширенный метод для анализа частот, подходящий для разных инструментов
    private func hasMusicalFrequencies() -> Bool {
        let musicalFrequencyRanges = [
            (50.0, 200.0),    // Bass drum, низкие ноты гитары/баса
            (200.0, 500.0),   // Snare, средние ноты гитары
            (500.0, 1200.0),  // Средние частоты многих инструментов
            (1200.0, 5000.0), // Высокие частоты гитары и других инструментов
            (5000.0, 12000.0) // Hi-hat and cymbals
        ]

        for freq in dominantFrequencies {
            for range in musicalFrequencyRanges {
                if freq >= range.0 && freq <= range.1 {
                    return true
                }
            }
        }

        return false
    }

    private func performFFT(on buffer: UnsafeMutablePointer<Float>, frameCount: Int) {
        let bufferSize = min(frameCount, self.bufferSize)

        var realPart = [Float](repeating: 0, count: n)
        var imagPart = [Float](repeating: 0, count: n)
        var realOutput = [Float](repeating: 0, count: n/2)

        // Copy audio data to real part of input buffer
        for i in 0..<bufferSize {
            realPart[i] = buffer[i]
        }

        // Apply Hann window
        var window = [Float](repeating: 0, count: bufferSize)
        vDSP_hann_window(&window, vDSP_Length(bufferSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(realPart, 1, window, 1, &realPart, 1, vDSP_Length(bufferSize))

        // Perform FFT
        realPart.withUnsafeMutableBufferPointer { realPtr in
            imagPart.withUnsafeMutableBufferPointer { imagPtr in
                var complex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                let setup = fftSetup!

                // Forward FFT
                vDSP_fft_zrip(setup, &complex, 1, vDSP_Length(log2n), FFTDirection(kFFTDirection_Forward))

                // Calculate magnitude
                var magnitudes = [Float](repeating: 0, count: n/2)
                vDSP_zvmags(&complex, 1, &magnitudes, 1, vDSP_Length(n/2))

                // Find dominant frequencies
                dominantFrequencies = findDominantFrequencies(magnitudes, frameCount: frameCount)
            }
        }
    }

    private func findDominantFrequencies(_ magnitudes: [Float], frameCount: Int) -> [Double] {
        var peaks: [(frequency: Double, magnitude: Float)] = []
        let sampleRate = 44100.0

        for i in 1..<(magnitudes.count - 1) {
            if magnitudes[i] > magnitudes[i-1] && magnitudes[i] > magnitudes[i+1] && magnitudes[i] > 0.01 {
                let frequency = Double(i) * sampleRate / Double(n)
                peaks.append((frequency, magnitudes[i]))
            }
        }

        peaks.sort { $0.magnitude > $1.magnitude }
        return peaks.prefix(5).map { $0.frequency }
    }

    private func hasDrumLikeFrequencies() -> Bool {
        let drumFrequencyRanges = [
            (50.0, 200.0),    // Bass drum
            (200.0, 400.0),   // Snare (low)
            (900.0, 5000.0),  // Claps, snare (high)
            (5000.0, 12000.0) // Hi-hat and cymbals
        ]

        for freq in dominantFrequencies {
            for range in drumFrequencyRanges {
                if freq >= range.0 && freq <= range.1 {
                    return true
                }
            }
        }

        return false
    }

    // Add this function to check for likely metronome echoes.  This is a placeholder and needs more sophisticated logic.
    private func isLikelyMetronomeEcho() -> Bool {
        // Implement logic to detect if the current audio level is likely an echo of the metronome.
        // This might involve checking for similar patterns in recent audio levels or frequency analysis.
        // This is a placeholder, replace with actual logic.
        return false
    }
}