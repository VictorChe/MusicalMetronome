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
        if #available(iOS 17.0, *) {
            Task {
                let granted = await AVAudioApplication.requestRecordPermissionWithCompletionHandler()
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                    if granted {
                        self.setupAudioEngine()
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.setupAudioEngine()
                    }
                }
            }
        }
    }

    private func setupAudioEngine() {
        do {
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }

            // Настраиваем аудио сессию только для записи
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement)
            try AVAudioSession.sharedInstance().setActive(true)

            inputNode = audioEngine.inputNode
            guard let inputNode = inputNode else { return }

            let inputFormat = inputNode.outputFormat(forBus: 0)
            let recordingFormat = AVAudioFormat(
                standardFormatWithSampleRate: inputFormat.sampleRate,
                channels: 1
            )

            guard let recordingFormat = recordingFormat else {
                print("Ошибка: Не удалось создать формат записи")
                return
            }

            inputNode.installTap(onBus: 0,
                               bufferSize: UInt32(bufferSize),
                               format: recordingFormat) { [weak self] (buffer, time) in
                self?.processAudioBuffer(buffer)
            }

            audioEngine.prepare()
        } catch {
            print("Ошибка настройки аудио движка: \(error.localizedDescription)")
        }
    }

    func startMonitoring() {
        guard permissionGranted, !isMonitoring, let audioEngine = audioEngine else { return }

        do {
            try audioEngine.start()
            isMonitoring = true
        } catch {
            print("Ошибка запуска аудио мониторинга: \(error.localizedDescription)")
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
        let previousAverage = previousAudioLevels.dropLast().reduce(0, +) / Double(previousAudioLevels.count - 1)
        let isVolumeSpike = currentLevel > previousAverage + beatDetectionThreshold
        let hasDrumFrequencies = hasDrumLikeFrequencies()

        if isVolumeSpike && hasDrumFrequencies {
            isBeatDetected = true
            onAudioDetected?(currentLevel)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isBeatDetected = false
            }
        }
    }

    private func performFFT(on buffer: UnsafeMutablePointer<Float>, frameCount: Int) {
        let bufferSize = min(frameCount, self.bufferSize)
        var realPart = [Float](repeating: 0, count: n)
        var imagPart = [Float](repeating: 0, count: n)
        var window = [Float](repeating: 0, count: bufferSize)

        for i in 0..<bufferSize {
            realPart[i] = buffer[i]
        }
        vDSP_hann_window(&window, vDSP_Length(bufferSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(realPart, 1, window, 1, &realPart, 1, vDSP_Length(bufferSize))

        var magnitudes = [Float](repeating: 0, count: n/2)
        realPart.withUnsafeMutableBufferPointer { realPtr in
            imagPart.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                vDSP_fft_zrip(fftSetup!, &splitComplex, 1, vDSP_Length(log2n), FFTDirection(kFFTDirection_Forward))
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(n/2))
            }
        }

        dominantFrequencies = findDominantFrequencies(magnitudes, frameCount: frameCount)
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
}