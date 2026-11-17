import Foundation

/// 计时阶段：专注 / 短休息 / 长休息。
enum Phase: String, Codable, CaseIterable, Identifiable {
    case focus
    case shortBreak
    case longBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: return "专注"
        case .shortBreak: return "短休息"
        case .longBreak: return "长休息"
        }
    }

    var subtitle: String {
        switch self {
        case .focus: return "保持专注，屏蔽干扰"
        case .shortBreak: return "起身走动，放松眼睛"
        case .longBreak: return "好好休息一会儿"
        }
    }

    var symbol: String {
        switch self {
        case .focus: return "flame.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "moon.stars.fill"
        }
    }

    var isBreak: Bool { self != .focus }
}

/// 一个任务。
struct FocusTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String = ""
    var note: String = ""
    var estimate: Int = 4
    var done: Int = 0
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var tintHex: UInt32 = 0xFF5E6C

    var progress: Double {
        guard estimate > 0 else { return isCompleted ? 1 : 0 }
        return min(1, Double(done) / Double(estimate))
    }

    var remaining: Int { max(0, estimate - done) }
}

/// 一次已完成的专注记录。
struct SessionRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var finishedAt: Date = Date()
    var phase: Phase = .focus
    var minutes: Int = 25
    var taskTitle: String?
}

/// 全部可调设置。
struct AppSettings: Codable, Equatable {
    var focusMinutes: Int = 25
    var shortBreakMinutes: Int = 5
    var longBreakMinutes: Int = 15
    var sessionsBeforeLongBreak: Int = 4

    var autoStartBreaks: Bool = true
    var autoStartFocus: Bool = false
    var strictMode: Bool = true

    var hapticsEnabled: Bool = true
    var soundEnabled: Bool = true
    var liveActivityEnabled: Bool = true

    var dailyGoal: Int = 8
    var noiseKind: NoiseKind = .off
    var noiseVolume: Double = 0.45

    var keepScreenAwake: Bool = true

    static let `default` = AppSettings()
}
