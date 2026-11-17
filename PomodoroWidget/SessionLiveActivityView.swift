import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

struct SessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionAttributes.self) { context in
            LockScreenSessionView(context: context)
                .activityBackgroundTint(Color(hex: 0x140E1B))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.symbolName)
                            .font(.system(size: 13, weight: .semibold))
                        Text(context.state.statusText)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color(hex: context.state.tintHex))
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    countdown(context.state)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.trailing, 6)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    progressBar(context.state)
                }
            } compactLeading: {
                Image(systemName: context.state.symbolName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: context.state.tintHex))
            } compactTrailing: {
                countdown(context.state)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .frame(maxWidth: 54)
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: context.state.symbolName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: context.state.tintHex))
            }
            .keylineTint(Color(hex: context.state.tintHex))
        }
    }

    // MARK: - 组件

    @ViewBuilder
    private func countdown(_ state: SessionAttributes.ContentState) -> some View {
        if state.isPaused || state.isFinished {
            Text(Self.format(seconds: state.remainingSeconds))
                .monospacedDigit()
        } else {
            Text(timerInterval: Date()...max(state.endDate, Date().addingTimeInterval(1)), countsDown: true)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func progressBar(_ state: SessionAttributes.ContentState) -> some View {
        let total = max(1, state.totalSeconds)
        let done = min(1.0, max(0.0, 1.0 - Double(state.remainingSeconds) / Double(total)))
        VStack(spacing: 6) {
            ProgressView(value: state.isFinished ? 1.0 : done)
                .progressViewStyle(.linear)
                .tint(Color(hex: state.tintHex))
            HStack {
                Text(state.isFinished ? "本轮完成" : "专注进度")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("\(Int((state.isFinished ? 1.0 : done) * 100))%")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    static func format(seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }
}

// MARK: - 锁屏卡片

struct LockScreenSessionView: View {
    let context: ActivityViewContext<SessionAttributes>

    private var state: SessionAttributes.ContentState { context.state }
    private var tint: Color { Color(hex: state.tintHex) }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: state.symbolName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(state.statusText)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(tint)
                Text(state.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                if state.isFinished {
                    Text("完成")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(tint)
                } else if state.isPaused {
                    Text(SessionLiveActivityWidget.format(seconds: state.remainingSeconds))
                        .font(.system(size: 26, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                } else {
                    Text(timerInterval: Date()...max(state.endDate, Date().addingTimeInterval(1)), countsDown: true)
                        .font(.system(size: 26, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                Text("番茄专注")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - 颜色

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
