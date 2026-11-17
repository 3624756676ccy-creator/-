import AVFoundation
import Foundation

/// 白噪音种类。
enum NoiseKind: String, Codable, CaseIterable, Identifiable {
    case off
    case white
    case brown
    case pink

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: return "安静"
        case .white: return "白噪音"
        case .brown: return "棕噪音"
        case .pink: return "粉噪音"
        }
    }

    var symbol: String {
        switch self {
        case .off: return "speaker.slash.fill"
        case .white: return "wind"
        case .brown: return "water.waves"
        case .pink: return "cloud.rain.fill"
        }
    }

    static var selectable: [NoiseKind] { allCases.filter { $0 != .off } }
}

/// 程序化生成并循环播放的背景噪音，不占用 App 包体。
final class NoiseEngine {
    static let shared = NoiseEngine()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isConnected = false
    private var cachedKind: NoiseKind = .off
    private var cachedBuffer: AVAudioPCMBuffer?

    private(set) var currentKind: NoiseKind = .off

    private init() {}

    private static let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!

    func start(kind: NoiseKind, volume: Double) {
        guard kind != .off else {
            stop()
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])

            if !isConnected {
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: Self.format)
                isConnected = true
            }

            if cachedKind != kind || cachedBuffer == nil {
                cachedBuffer = Self.makeBuffer(kind: kind)
                cachedKind = kind
            }
            guard let buffer = cachedBuffer else { return }

            player.volume = Float(max(0.0, min(1.0, volume)))
            if !engine.isRunning { try engine.start() }
            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            player.play()
            currentKind = kind
        } catch {
            currentKind = .off
        }
    }

    func setVolume(_ volume: Double) {
        player.volume = Float(max(0.0, min(1.0, volume)))
    }

    func stop() {
        player.stop()
        currentKind = .off
        engine.pause()
    }

    private static func makeBuffer(kind: NoiseKind) -> AVAudioPCMBuffer? {
        let sampleRate = 44_100.0
        let seconds = 6.0
        let frameCount = AVAudioFrameCount(sampleRate * seconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        let total = Int(frameCount)
        var samples = [Float](repeating: 0, count: total)

        var brown = 0.0
        var pink0 = 0.0
        var pink1 = 0.0
        var pink2 = 0.0

        for index in 0..<total {
            let white = Double.random(in: -1.0...1.0)
            switch kind {
            case .white:
                samples[index] = Float(white * 0.16)
            case .brown:
                brown = (brown + 0.02 * white) / 1.02
                samples[index] = Float(brown * 3.4)
            case .pink:
                pink0 = 0.99765 * pink0 + white * 0.0990460
                pink1 = 0.96300 * pink1 + white * 0.2965164
                pink2 = 0.57000 * pink2 + white * 1.0526913
                samples[index] = Float((pink0 + pink1 + pink2 + white * 0.1848) * 0.088)
            case .off:
                samples[index] = 0
            }
        }

        // 首尾淡入淡出，避免循环接缝出现「咔哒」声。
        let fade = min(2048, total / 8)
        if fade > 1 {
            for index in 0..<fade {
                let gain = Float(index) / Float(fade)
                samples[index] *= gain
                samples[total - 1 - index] *= gain
            }
        }

        guard let channels = buffer.floatChannelData else { return nil }
        for channelIndex in 0..<Int(format.channelCount) {
            let channel = channels[channelIndex]
            for index in 0..<total {
                channel[index] = max(-1.0, min(1.0, samples[index]))
            }
        }
        return buffer
    }
}
