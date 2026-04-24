import AVFoundation
import Combine

/// Handles voice capture and playback for peer-to-peer (Bluetooth/WiFi Direct) calls.
final class AudioStreamingService: NSObject, ObservableObject {
    @Published var isCapturing: Bool = false

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFormat: AVAudioFormat?

    var onAudioCaptured: ((Data) -> Void)?

    override init() {
        super.init()
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        audioEngine.attach(playerNode)
        // Use nil format so AVAudioEngine resolves the format after the session is active.
        // Passing inputNode.outputFormat here crashes because sampleRate is 0 before session setup.
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
    }

    func startCapture() {
        guard !isCapturing else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
            try session.setActive(true)

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            audioFormat = format

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer)
            }

            try audioEngine.start()
            isCapturing = true
        } catch {
            print("[Audio] Failed to start capture: \(error)")
        }
    }

    func stopCapture() {
        guard isCapturing else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        isCapturing = false
    }

    func playReceivedAudio(_ data: Data) {
        guard let format = audioFormat,
              let buffer = pcmBuffer(from: data, format: format) else { return }
        if !audioEngine.isRunning {
            try? audioEngine.start()
        }
        if !playerNode.isPlaying {
            playerNode.play()
        }
        playerNode.scheduleBuffer(buffer)
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let data = bufferToData(buffer) else { return }
        onAudioCaptured?(data)
    }

    private func bufferToData(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let channelData = buffer.floatChannelData else { return nil }
        let frameCount = Int(buffer.frameLength)
        var samples = [Float](repeating: 0, count: frameCount)
        for i in 0..<frameCount {
            samples[i] = channelData[0][i]
        }
        return Data(bytes: samples, count: frameCount * MemoryLayout<Float>.size)
    }

    private func pcmBuffer(from data: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = data.count / MemoryLayout<Float>.size
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return nil }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        data.withUnsafeBytes { ptr in
            if let float32Ptr = ptr.bindMemory(to: Float.self).baseAddress,
               let channelData = buffer.floatChannelData {
                channelData[0].update(from: float32Ptr, count: frameCount)
            }
        }
        return buffer
    }
}
