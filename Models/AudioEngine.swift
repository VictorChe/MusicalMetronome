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
    
    // Кэшируем предыдущие значения для сравнения
    private var previousAudioLevels: [Double] = []
    private let beatDetectionThreshold: Double = 0.15
    
    // Для FFT анализа
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
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        guard let inputNode = inputNode else { return }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: UInt32(bufferSize), format: recordingFormat) { [weak self] (buffer, when) in
            self?.processAudioBuffer(buffer)
        }
    }
    
    func startMonitoring() {
        guard permissionGranted, !isMonitoring, let audioEngine = audioEngine else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isMonitoring = true
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
        
        // Вычисляем средний уровень громкости
        var sum: Float = 0
        vDSP_maxmgv(channelData, 1, &sum, vDSP_Length(frameLength))
        
        // Применяем FFT для анализа частот
        performFFT(on: channelData, frameCount: frameLength)
        
        let currentLevel = Double(sum)
        DispatchQueue.main.async {
            self.audioLevel = currentLevel
            
            // Добавляем текущий уровень в историю
            self.previousAudioLevels.append(currentLevel)
            if self.previousAudioLevels.count > 5 {
                self.previousAudioLevels.removeFirst()
            }
            
            // Обнаружение удара на основе резкого изменения громкости
            // и преобладания частот, характерных для ударов
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
        
        var realIn = [Float](repeating: 0, count: n)
        var imagIn = [Float](repeating: 0, count: n)
        var realOut = [Float](repeating: 0, count: n/2)
        var imagOut = [Float](repeating: 0, count: n/2)
        
        // Копируем аудио данные в реальную часть входного буфера
        for i in 0..<bufferSize {
            realIn[i] = buffer[i]
        }
        
        // Применяем оконную функцию Ханна
        var window = [Float](repeating: 0, count: bufferSize)
        vDSP_hann_window(&window, vDSP_Length(bufferSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(realIn, 1, window, 1, &realIn, 1, vDSP_Length(bufferSize))
        
        // Создаем комплексный входной буфер
        var complex = DSPSplitComplex(realp: &realIn, imagp: &imagIn)
        
        // Выполняем FFT
        vDSP_ctoz([DSPComplex](repeating: DSPComplex(), count: n/2), 2, &complex, 1, vDSP_Length(n/2))
        vDSP_fft_zrip(fftSetup!, &complex, 1, vDSP_Length(log2n), FFTDirection(kFFTDirection_Forward))
        
        // Рассчитываем магнитуду
        vDSP_ztoc(&complex, 1, [DSPComplex](repeating: DSPComplex(), count: n/2), 2, vDSP_Length(n/2))
        vDSP_zvabs(&complex, 1, &realOut, 1, vDSP_Length(n/2))
        
        // Находим доминирующие частоты
        dominantFrequencies = findDominantFrequencies(realOut, frameCount: frameCount)
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
            (50.0, 200.0),    // Басовый барабан
            (200.0, 400.0),   // Малый барабан (низкие частоты)
            (900.0, 5000.0),  // Хлопки, малый барабан (высокие частоты)
            (5000.0, 12000.0) // Хай-хэт и тарелки
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
