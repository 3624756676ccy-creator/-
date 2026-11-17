import SwiftUI

enum MainTab: String, CaseIterable, Identifiable {
    case focus
    case tasks
    case stats
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: return "专注"
        case .tasks: return "任务"
        case .stats: return "统计"
        case .settings: return "设置"
        }
    }

    var symbol: String {
        switch self {
        case .focus: return "timer"
        case .tasks: return "checklist"
        case .stats: return "chart.bar.fill"
        case .settings: return "slider.horizontal.3"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: MainTab = .focus

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case .focus:
                        FocusView()
                    case .tasks:
                        TasksView()
                    case .stats:
                        StatsView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                TabBar(selection: $tab)
            }

            if let toast = model.toast {
                ToastView(text: toast)
                    .padding(.bottom, 96)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            model.bootstrap()
            Notifications.requestPermission()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            model.syncAfterForeground()
            ScreenTimeManager.shared.refreshAuthorizationState()
        }
    }
}

struct TabBar: View {
    @Binding var selection: MainTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainTab.allCases) { item in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selection = item
                    }
                    Haptics.tap()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 17, weight: .semibold))
                        Text(item.title)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selection == item ? Color.white : Color.white.opacity(0.42))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background {
                        if selection == item {
                            Capsule()
                                .fill(Theme.coral.opacity(0.20))
                                .overlay(
                                    Capsule().strokeBorder(Theme.coral.opacity(0.38), lineWidth: 1)
                                )
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            Capsule().fill(Color(hex: 0x1C1222).opacity(0.94))
        )
        .overlay(
            Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
}
