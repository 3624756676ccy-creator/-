import ActivityKit
import Foundation

/// App 与 Live Activity 扩展共享的属性定义（同一份源码编译进两个 target）。
struct SessionAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: String
        var title: String
        var endDate: Date
        var isPaused: Bool
        var isFinished: Bool
        var remainingSeconds: Int
        var totalSeconds: Int
    }

    var phase: String
}

extension SessionAttributes.ContentState {
    /// 供锁屏 / 灵动岛展示用的状态文案。
    var statusText: String {
        if isFinished { return "已完成" }
        if isPaused { return "已暂停" }
        return phase == "focus" ? "专注中" : "休息中"
    }

    var symbolName: String {
        if isFinished { return "checkmark.circle.fill" }
        switch phase {
        case "focus": return "flame.fill"
        case "longBreak": return "moon.stars.fill"
        default: return "cup.and.saucer.fill"
        }
    }

    var tintHex: UInt32 {
        if isPaused { return 0xFFC46B }
        if isFinished { return 0x4ADE9B }
        return phase == "focus" ? 0xFF5E6C : 0x4ADE9B
    }
}
