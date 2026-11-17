import ActivityKit
import Foundation
import SwiftUI

/// Live Activity（锁屏实时倒计时 + 灵动岛）控制。
@MainActor
final class LiveActivityController {
    static let shared = LiveActivityController()

    private var activity: Activity<SessionAttributes>?

    private init() {}

    var isSystemEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(phase: Phase, title: String, endDate: Date, totalSeconds: Int) {
        guard isSystemEnabled else { return }

        let state = SessionAttributes.ContentState(
            phase: phase.rawValue,
            title: title,
            endDate: endDate,
            isPaused: false,
            isFinished: false,
            remainingSeconds: max(0, Int(endDate.timeIntervalSinceNow.rounded(.up))),
            totalSeconds: totalSeconds
        )

        if let activity {
            Task { await activity.update(ActivityContent(state: state, staleDate: endDate)) }
            return
        }

        do {
            activity = try Activity.request(
                attributes: SessionAttributes(phase: phase.rawValue),
                content: ActivityContent(state: state, staleDate: endDate),
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    func pause(phase: Phase, title: String, remaining: Int, totalSeconds: Int) {
        guard let activity else { return }
        let state = SessionAttributes.ContentState(
            phase: phase.rawValue,
            title: title,
            endDate: Date().addingTimeInterval(TimeInterval(max(1, remaining))),
            isPaused: true,
            isFinished: false,
            remainingSeconds: max(0, remaining),
            totalSeconds: totalSeconds
        )
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    func finish(phase: Phase, title: String) {
        guard let activity else { return }
        let state = SessionAttributes.ContentState(
            phase: phase.rawValue,
            title: title,
            endDate: Date(),
            isPaused: false,
            isFinished: true,
            remainingSeconds: 0,
            totalSeconds: 0
        )
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.activity = nil
    }

    func end() {
        guard let activity else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
        self.activity = nil
    }
}
