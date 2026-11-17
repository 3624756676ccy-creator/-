import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var screenTime = ScreenTimeManager.shared
    @State private var showBlockSheet = false
    @State private var showClearConfirm = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 15) {
                header
                durationCard
                automationCard
                soundCard
                shieldCard
                dataCard
                aboutCard
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
        .sheet(isPresented: $showBlockSheet) {
            BlockAppsView()
        }
        .onChange(of: model.settings) { _, _ in
            model.refreshIdleTimer()
        }
        .confirmationDialog("确定清空全部专注记录？", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("清空记录", role: .destructive) {
                model.records.removeAll()
                model.showToast("记录已清空")
            }
            Button("取消", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("设置")
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("调成属于你的节奏")
                .font(.system(size: 11.5, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 时长

    private var durationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 15) {
                SectionTitle(title: "时长")
                StepperRow(title: "专注", value: $model.settings.focusMinutes, range: 1...120)
                Divider().overlay(Color.white.opacity(0.06))
                StepperRow(title: "短休息", value: $model.settings.shortBreakMinutes, range: 1...60)
                Divider().overlay(Color.white.opacity(0.06))
                StepperRow(title: "长休息", value: $model.settings.longBreakMinutes, range: 1...90)
                Divider().overlay(Color.white.opacity(0.06))
                StepperRow(
                    title: "长休息间隔",
                    value: $model.settings.sessionsBeforeLongBreak,
                    range: 1...12,
                    unit: "个番茄"
                )
                Divider().overlay(Color.white.opacity(0.06))
                StepperRow(title: "每日目标", value: $model.settings.dailyGoal, range: 1...30, unit: "个")
            }
        }
    }

    // MARK: - 自动化

    private var automationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 15) {
                SectionTitle(title: "自动化")
                ToggleRow(
                    title: "自动开始休息",
                    subtitle: "专注结束后直接进入休息倒计时",
                    isOn: $model.settings.autoStartBreaks
                )
                Divider().overlay(Color.white.opacity(0.06))
                ToggleRow(
                    title: "自动开始下一个番茄",
                    subtitle: "休息结束后立刻开始新的专注",
                    isOn: $model.settings.autoStartFocus
                )
                Divider().overlay(Color.white.opacity(0.06))
                ToggleRow(
                    title: "严格模式",
                    subtitle: "专注进行中不能暂停、跳过或重置",
                    isOn: $model.settings.strictMode
                )
                Divider().overlay(Color.white.opacity(0.06))
                ToggleRow(
                    title: "专注时保持屏幕常亮",
                    subtitle: "关闭更省电",
                    isOn: $model.settings.keepScreenAwake
                )
            }
        }
    }

    // MARK: - 声音

    private var soundCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 15) {
                SectionTitle(title: "声音与反馈")

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
                }

                if model.settings.noiseKind != .off {
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.wave.1.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                        Slider(
                            value: Binding(
                                get: { model.settings.noiseVolume },
                                set: { model.setNoiseVolume($0) }
                            ),
                            in: 0...1
                        )
                        .tint(Theme.coral)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                Divider().overlay(Color.white.opacity(0.06))

                ToggleRow(
                    title: "结束提示音",
                    subtitle: "阶段结束时播放三音提示",
                    isOn: $model.settings.soundEnabled
                )
                Divider().overlay(Color.white.opacity(0.06))
                ToggleRow(
                    title: "触感反馈",
                    isOn: $model.settings.hapticsEnabled
                )
                Divider().overlay(Color.white.opacity(0.06))
                ToggleRow(
                    title: "锁屏实时倒计时",
                    subtitle: "支持灵动岛与锁屏进度",
                    isOn: $model.settings.liveActivityEnabled
                )
            }
        }
    }

    // MARK: - 屏蔽

    private var shieldCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                SectionTitle(title: "专注屏蔽")

                HStack(spacing: 10) {
                    Image(systemName: screenTime.isAuthorized ? "checkmark.shield.fill" : "shield.slash.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(screenTime.isAuthorized ? Theme.mint : Theme.amber)
                    Text(screenTime.isAuthorized ? "屏幕使用时间已授权" : "未授权，屏蔽不可用")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text("\(screenTime.selectedCount) 项")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }

                PrimaryButton(
                    title: "管理屏蔽清单",
                    systemImage: "shield.lefthalf.filled",
                    gradient: Theme.focusGradient
                ) {
                    showBlockSheet = true
                }
            }
        }
    }

    // MARK: - 数据

    private var dataCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                SectionTitle(title: "数据")
                HStack {
                    Text("累计番茄")
                        .font(.system(size: 13.5, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text("\(model.totalFocusCount) 个 · \(model.totalFocusMinutes) 分钟")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Button {
                    showClearConfirm = true
                } label: {
                    Text("清空全部专注记录")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.coral)
                }
            }
        }
    }

    // MARK: - 关于

    private var aboutCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(title: "关于")
                HStack {
                    Text("番茄专注")
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("v\(Self.appVersion)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Text("纯本地运行，不上传任何数据。屏蔽能力来自系统 Screen Time 框架。")
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private static var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
    }
}
