import FamilyControls
import Foundation
import ManagedSettings
import SwiftUI

/// 基于 Screen Time（FamilyControls + ManagedSettings）的应用屏蔽管理。
///
/// 注意：需要在真机上运行，且开发者账号必须获批
/// `com.apple.developer.family-controls` 能力，否则授权请求会失败。
@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var isShielding: Bool = false
    @Published var selection: FamilyActivitySelection = FamilyActivitySelection() {
        didSet { saveSelection() }
    }
    @Published var lastErrorMessage: String?

    private let store = ManagedSettingsStore()
    private let selectionKey = "pomodoro.screentime.selection.v1"

    private init() {
        restoreSelection()
        refreshAuthorizationState()
    }

    // MARK: - 授权

    func refreshAuthorizationState() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    /// 请求「屏幕使用时间」授权（家庭控制）。首次会弹出系统授权面板。
    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                refreshAuthorizationState()
                if isAuthorized {
                    lastErrorMessage = nil
                } else {
                    lastErrorMessage = "未获得授权，请在「设置 → 屏幕使用时间」中允许本 App。"
                }
            } catch {
                refreshAuthorizationState()
                lastErrorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - 选择

    var selectedCount: Int {
        selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
    }

    var hasSelection: Bool { selectedCount > 0 }

    var summaryText: String {
        guard selectedCount > 0 else { return "尚未选择要屏蔽的 App 或网站" }
        return "已选择 \(selectedCount) 项（App \(selection.applicationTokens.count) · 类别 \(selection.categoryTokens.count) · 网站 \(selection.webDomainTokens.count)）"
    }

    // MARK: - 屏蔽

    /// 应用屏蔽（专注开始时调用）。
    func activateShield() {
        guard isAuthorized else {
            lastErrorMessage = "需要先授予「屏幕使用时间」权限才能屏蔽 App。"
            return
        }
        guard hasSelection else {
            lastErrorMessage = "请先选择需要屏蔽的 App 或网站。"
            return
        }

        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
        } else {
            store.shield.applications = nil
        }

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        } else {
            store.shield.applicationCategories = nil
        }

        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens
        } else {
            store.shield.webDomains = nil
        }

        isShielding = true
        lastErrorMessage = nil
    }

    /// 解除屏蔽（专注结束 / 放弃时调用）。
    func deactivateShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        isShielding = false
    }

    func clearSelection() {
        selection = FamilyActivitySelection()
        deactivateShield()
    }

    // MARK: - 持久化

    private func saveSelection() {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        UserDefaults.standard.set(data, forKey: selectionKey)
    }

    private func restoreSelection() {
        guard let data = UserDefaults.standard.data(forKey: selectionKey),
              let stored = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else { return }
        selection = stored
    }
}
