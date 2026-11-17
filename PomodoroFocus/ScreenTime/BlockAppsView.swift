import FamilyControls
import SwiftUI

/// 专注屏蔽设置页：授权 → 选择 App / 网站 → 屏蔽。
struct BlockAppsView: View {
    @StateObject private var manager = ScreenTimeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        authorizationCard
                        selectionCard
                        shieldCard
                        footnote
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("专注屏蔽")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
            .sheet(isPresented: $showPicker) {
                FamilyPickerSheet(selection: $manager.selection)
            }
            .onAppear { manager.refreshAuthorizationState() }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - 卡片

    private var authorizationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: manager.isAuthorized ? "checkmark.shield.fill" : "shield.slash.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(manager.isAuthorized ? Theme.mint : Theme.amber)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(manager.isAuthorized ? "已获得屏幕使用时间权限" : "尚未获得权限")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("屏蔽能力由系统 Screen Time 提供")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                }

                if !manager.isAuthorized {
                    PrimaryButton(
                        title: "授权屏幕使用时间",
                        systemImage: "hand.raised.fill",
                        gradient: Theme.focusGradient
                    ) {
                        manager.requestAuthorization()
                    }
                }

                if let message = manager.lastErrorMessage {
                    Text(message)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.amber.opacity(0.9))
                }
            }
        }
    }

    private var selectionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("屏蔽范围")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(manager.summaryText)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)

                PrimaryButton(
                    title: "选择 App 与网站",
                    systemImage: "square.grid.2x2.fill",
                    gradient: LinearGradient(
                        colors: [Color(hex: 0x5B5BD6), Color(hex: 0x8B5CF6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                ) {
                    if manager.isAuthorized {
                        showPicker = true
                    } else {
                        manager.requestAuthorization()
                    }
                }

                if manager.hasSelection {
                    Button(role: .destructive) {
                        manager.clearSelection()
                    } label: {
                        Text("清空屏蔽清单")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.coral)
                    }
                }
            }
        }
    }

    private var shieldCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: Binding(
                    get: { manager.isShielding },
                    set: { newValue in
                        if newValue {
                            manager.activateShield()
                        } else {
                            manager.deactivateShield()
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("立即屏蔽")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("专注开始时会自动启用，结束后自动解除")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .tint(Theme.coral)

                if manager.isShielding {
                    Label("被选中的 App 现在打开会显示专注提示页", systemImage: "lock.fill")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.mint)
                }
            }
        }
    }

    private var footnote: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(title: "说明")
            Text("• 该功能使用 Apple Screen Time 框架，只在真机上生效，模拟器不可用。\n• 需要开发者账号拥有 com.apple.developer.family-controls 能力（需向 Apple 申请并获批）。\n• 自签/侧载安装若未包含该能力，App 其余功能正常，屏蔽会降级为不可用并给出提示。")
                .font(.system(size: 11.5, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}

/// 系统自带的 App / 网站选择面板。
struct FamilyPickerSheet: View {
    @Binding var selection: FamilyActivitySelection
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FamilyActivityPicker(selection: $selection)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("选择要屏蔽的对象")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") { dismiss() }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                }
        }
    }
}
