import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var screenTime = ScreenTimeManager.shared
    @State private var showBlockSheet = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header
                dial
                controls
                chipRow
                blockCard
                footerNote
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
        .sheet(isPresented: $showBlockSheet) {
            BlockAppsView()
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(greeting)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Text("今日 \(model.todayFocusCount)/\(max(1, model.settings.dailyGoal)) 个")
                    Text("·")
                    Text("连续 \(model.streakDays) 天")
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.48))
            }

            Spacer()

            GoalRing(
                progress: model.goalProgress,
                label: "\(Int(model.goalProgress * 100))%"
            )
            .frame(width: 56, height: 56)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<9: return "早上好，开个好头"
        case 9..<12: return "上午专注时间"
        case 12..<14: return "午后别急着冲刺"
        case 14..<18: return "下午继续加油"
        case 18..<22: return "晚上好，收个尾"
        default: return "夜深了，早点休息"
        }
    }

    // MARK: - 表盘

    private var dial: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.tint(for: model.phase).opacity(0.28), Color.clear],
                        center: .center,
                        startRadius: 18,
                        endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(model.isRunning ? 1.06 : 0.94)
                .animation(
                    model.isRunning
                        ? Animation.easeInOut(duration: 2.6).repeatForever(autoreverses: true)
                        : Animation.easeOut(duration: 0.4),
                    value: model.isRunning
                )

            TimerRing(
                progress: model.progress,
                gradient: Theme.accent(for: model.phase),
                glow: Theme.tint(for: model.phase)
            )
            .frame(width: 288, height: 288)

            VStack(spacing: 9) {
                HStack(spacing: 6) {
                    Image(systemName: model.phase.symbol)
                        .font(.system(size: 11, weight: .bold))
                    Text(model.phase.title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(2.2)
                }
                .foregroundStyle(Theme.tint(for: model.phase))

                Text(model.timeText)
                    .font(.system(size: 66, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.2), value: model.remaining)

                Text(model.displayTitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                    .frame(maxWidth: 190)

                if model.strictActive {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill").font(.system(size: 9, weight: .bold))
                        Text("严格模式").font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Theme.amber)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.amber.opacity(0.14)))
                }
            }
        }
        .frame(height: 312)
    }

    // MARK: - 控制

    private var controls: some View {
        HStack(spacing: 26) {
            CircleIconButton(symbol: "arrow.counterclockwise", size: 54, tint: .white.opacity(0.72)) {
                model.resetCurrent()
            }

            Button {
                model.toggle()
                if model.settings.hapticsEnabled { Haptics.tap() }
            } label: {
                ZStack {
                    Circle()
                        .fill(Theme.accent(for: model.phase))
                        .frame(width: 86, height: 86)
                        .shadow(color: Theme.tint(for: model.phase).opacity(0.45), radius: 22, y: 10)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                        .frame(width: 86, height: 86)
                    Image(systemName: model.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: model.isRunning ? 0 : 2)
                }
            }
            .buttonStyle(TapScale())

            CircleIconButton(symbol: "forward.end.fill", size: 54, tint: .white.opacity(0.72)) {
                model.skipPhase()
            }
        }
        .padding(.top, 2)
    }

    // MARK: - 快捷开关

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(NoiseKind.selectable) { kind in
                    Button {
                        model.setNoise(kind)
                    } label: {
                        ChipView(
                            title: kind.title,
                            symbol: kind.symbol,
                            isOn: model.settings.noiseKind == kind
                        )
                    }
                    .buttonStyle(TapScale())
                }

                Button {
                    model.toggleStrict()
                } label: {
                    ChipView(
                        title: model.settings.strictMode ? "严格模式" : "宽松模式",
                        symbol: "lock.shield.fill",
                        isOn: model.settings.strictMode
                    )
                }
                .buttonStyle(TapScale())
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - 屏蔽状态

    private var blockCard: some View {
        Button {
            showBlockSheet = true
        } label: {
            GlassCard(padding: 16) {
                HStack(spacing: 13) {
                    ZStack {
                        Circle()
                            .fill(Theme.coral.opacity(0.16))
                            .frame(width: 44, height: 44)
                        Image(systemName: blockSymbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.coral)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(blockTitle)
                            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(blockSubtitle)
                            .font(.system(size: 11.5, design: .rounded))
                            .foregroundStyle(.white.opacity(0.48))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.28))
                }
            }
        }
        .buttonStyle(TapScale())
    }

    private var blockSymbol: String {
        if !screenTime.isAuthorized { return "shield.slash.fill" }
        return screenTime.hasSelection ? "shield.lefthalf.filled" : "plus.circle.fill"
    }

    private var blockTitle: String {
        if !screenTime.isAuthorized { return "开启 App 屏蔽" }
        if screenTime.isShielding { return "正在屏蔽 \(screenTime.selectedCount) 项干扰" }
        return screenTime.hasSelection ? "已准备好屏蔽 \(screenTime.selectedCount) 项" : "选择要屏蔽的 App"
    }

    private var blockSubtitle: String {
        if !screenTime.isAuthorized { return "授权屏幕使用时间后，专注期间无法打开选定 App" }
        if screenTime.isShielding { return "专注结束后自动解除屏蔽" }
        return "专注开始时自动屏蔽，休息时自动解除"
    }

    // MARK: - 底部

    private var footerNote: some View {
        VStack(spacing: 8) {
            if model.isRunning && model.phase == .focus {
                Text("长按此处 1.2 秒可放弃本次专注")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .onLongPressGesture(minimumDuration: 1.2) {
                        model.giveUp()
                    }
            } else {
                Text(model.phase.subtitle)
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.28))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 环形进度

struct TimerRing: View {
    var progress: Double
    var gradient: LinearGradient
    var glow: Color

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth = size * 0.066
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: max(0.003, min(1, progress)))
                    .stroke(
                        gradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: glow.opacity(0.5), radius: 16)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - 今日目标小环

struct GoalRing: View {
    var progress: Double
    var label: String

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: size * 0.10)
                Circle()
                    .trim(from: 0, to: max(0.004, min(1, progress)))
                    .stroke(
                        Theme.focusGradient,
                        style: StrokeStyle(lineWidth: size * 0.10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text(label)
                    .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
