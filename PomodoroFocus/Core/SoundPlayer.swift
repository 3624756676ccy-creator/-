import AVFoundation
import Foundation

/// 程序化合成的结束提示音（三段钟声），不依赖任何音频素材文件。
final class SoundPlayer {
    static let shared = SoundPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isPrepared = false
    private var cachedBuffer: AVAudioPCMBuffer?

    private init() {}

    func playChime() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])

            if !isPrepared {
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: Self.format)
                engine.mainMixerNode.outputVolume = 0.9
                try engine.start()
                isPrepared = true
            }
            if cachedBuffer == nil { cachedBuffer = Self.makeChimeBuffer() }
            guard let buffer = cachedBuffer else { return }

            if !engine.isRunning { try engine.start() }
            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            player.play()
        } catch {
            // 静默失败：播放提示音不属于关键路径。
        }
    }

    private static let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    private static func makeChimeBuffer() -> AVAudioPCMBuffer? {
        let sampleRate = 44_100.0
        let duration = 1.7
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        let notes: [(frequency: Double, start: Double, amplitude: Double)] = [
            (880.0, 0.00, 0.50),
            (1174.66, 0.11, 0.36),
            (1567.98, 0.22, 0.26)
        ]

        var samples = [Double](repeating: 0, count: Int(frameCount))
        for note in notes {
            let startIndex = Int(note.start * sampleRate)
            guard startIndex < samples.count else { continue }
            for index in startIndex..<samples.count {
                let t = Double(index - startIndex) / sampleRate
                let envelope = exp(-t * 4.6)
                let fundamental = sin(2 * Double.pi * note.frequency * t)
                let overtone = sin(2 * Double.pi * note.frequency * 2 * t) * 0.18
                samples[index] += (fundamental + overtone) * envelope * note.amplitude
            }
        }

        guard let channel = buffer.floatChannelData?[0] else { return nil }
        let fadeFrames = sampleRate * 0.25
        for index in 0..<Int(frameCount) {
            let remaining = Double(Int(frameCount) - index)
            let fade = remaining < fadeFrames ? remaining / fadeFrames : 1.0
            let value = samples[index] * 0.42 * fade
            channel[index] = Float(max(-1.0, min(1.0, value)))
        }
        return buffer
    }
}
