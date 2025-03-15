
import Foundation

protocol AudioServiceProtocol {
    var isMonitoring: Bool { get }
    var audioLevel: Double { get }
    func startMonitoring() throws
    func stopMonitoring()
    func notifyMetronomeClick()
}

protocol AudioDelegate: AnyObject {
    func audioService(_ service: AudioServiceProtocol, didDetectBeat intensity: Double)
    func audioService(_ service: AudioServiceProtocol, didFailWithError error: Error)
}
