import Foundation
import SwiftUI
import UIKit

/// 应用唯一数据源：计时引擎 + 任务 + 记录 + 设置。
@MainActor
final class AppModel: ObservableObject {

    // MARK: - 持久化数据

    @Published var settings: AppSettings = AppSettings() {
        didSet { persist(settings, key: Keys.settings) }
    }

    @Published var tasks: [FocusTask] = [] {
        didSet { persist(tasks, key: Keys.tasks) }
    }

    @Published var records: [SessionRecord] = [] {
        didSet { persist(records, key: Keys.records) }
    }

    @Published var activeTaskID: UUID? {
        didSet { UserDefaults.standard.set(activeTaskID?.uuidString, forKey: Keys.activeTask) }
    }

    // MARK: - 计时状态

    @Published private(set) var phase: Phase = .focus
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var remaining: Int = 25 * 60
    @Published private(set) var totalSeconds: Int = 25 * 60
    /// 本轮循环内已完成的专注个数，用于决定何时进入长休息。
    @Published private(set) var cycleCount: Int = 0

    @Published var toast: String?

    private var endDate: Date?
    private var ticker: Timer?
    private var didBootstrap = false
    private var toastToken = UUID()
    private var durationSignature = ""

    private enum Keys {
        static let settings = "pomodoro.settings.v1"
        static let tasks = "pomodoro.tasks.v1"
        static let records = "pomodoro.records.v1"
        static let activeTask = "pomodoro.activeTask.v1"
        static let isRunning = "pomodoro.isRunning.v1"
        static let phase = "pomodoro.phase.v1"
        static let remaining = "pomodoro.remaining.v1"
        static let total = "pomodoro.total.v1"
        static let endDate = "pomodoro.endDate.v1"
    }

    // MARK: - 派生状态

    var activeTask: FocusTask? {
        guard let activeTaskID else { return nil }
        return tasks.first { $0.id == activeTaskID }
    }

    var displayTitle: String {
        if phase == .focus, let title = activeTask?.title, !title.isEmpty { return title }
        return phase.title
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return min(1, max(0, Double(remaining) / Double(totalSeconds)))
    }

    var timeText: String {
        let clamped = max(0, remaining)
        let minutes = clamped / 60
        let seconds = clamped % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 严格模式仅在「专注进行中」时锁死操作。
    var strictActive: Bool {
        settings.strictMode && phase == .focus && isRunning
    }

    var goalProgress: Double {
        let goal = max(1, settings.dailyGoal)
        return min(1, Double(todayFocusCount) / Double(goal))
    }

    // MARK: - 启动

    func bootstrap() {
        guard !didBootstrap else { return }
        didBootstrap = true

        if let stored = Self.restore(AppSettings.self, key: Keys.settings) { settings = stored }
        durationSignature = "\(settings.focusMinutes)-\(settings.shortBreakMinutes)-\(settings.longBreakMinutes)"
        if let stored = Self.restore([FocusTask].self, key: Keys.tasks) { tasks = stored }
        if let stored = Self.restore([SessionRecord].self, key: Keys.records) { records = stored }
        if let raw = UserDefaults.standard.string(forKey: Keys.activeTask), let uuid = UUID(uuidString: raw) {
            activeTaskID = uuid
        }

        if let raw = UserDefaults.standard.string(forKey: Keys.phase), let stored = Phase(rawValue: raw) {
            phase = stored
        }

        let storedTotal = UserDefaults.standard.integer(forKey: Keys.total)
        let storedRemaining = UserDefaults.standard.integer(forKey: Keys.remaining)
        let wasRunning = UserDefaults.standard.bool(forKey: Keys.isRunning)
        let storedEnd = UserDefaults.standard.object(forKey: Keys.endDate) as? Date

        totalSeconds = storedTotal > 0 ? storedTotal : duration(for: phase)

        if wasRunning, let storedEnd, storedEnd > Date() {
            endDate = storedEnd
            remaining = max(0, Int(storedEnd.timeIntervalSinceNow.rounded(.up)))
            isRunning = true
            startTicker()
            activateBlockingIfNeeded()
            applyScreenAwake()
            if settings.liveActivityEnabled {
                LiveActivityController.shared.start(
                    phase: phase,
                    title: displayTitle,
                    endDate: storedEnd,
                    totalSeconds: totalSeconds
                )
            }
            Notifications.scheduleEnd(at: storedEnd, phase: phase)
        } else if wasRunning {
            // App 被杀掉期间这一轮已经结束，补记一条完成记录。
            finishExpiredSession(at: storedEnd ?? Date())
        } else {
            remaining = storedRemaining > 0 ? min(storedRemaining, totalSeconds) : totalSeconds
            totalSeconds = max(totalSeconds, remaining)
            ScreenTimeManager.shared.deactivateShield()
            persistState()
        }
    }

    // MARK: - 计时控制

    func start() {
        guard !isRunning else { return }
        if remaining <= 0 {
            totalSeconds = duration(for: phase)
            remaining = totalSeconds
        }
        if totalSeconds <= 0 { totalSeconds = max(1, remaining) }

        endDate = Date().addingTimeInterval(TimeInterval(remaining))
        isRunning = true
        startTicker()

        if phase == .focus { activateBlockingIfNeeded() }
        applyScreenAwake()

        if settings.noiseKind != .off {
            NoiseEngine.shared.start(kind: settings.noiseKind, volume: settings.noiseVolume)
        }
        if settings.liveActivityEnabled, let endDate {
            LiveActivityController.shared.start(
                phase: phase,
                title: displayTitle,
                endDate: endDate,
                totalSeconds: totalSeconds
            )
        }
        Notifications.scheduleEnd(at: endDate ?? Date(), phase: phase)
        if settings.hapticsEnabled { Haptics.soft() }
        persistState()
    }

    @discardableResult
    func pause() -> Bool {
        guard isRunning else { return false }
        guard !strictActive else {
            showToast("严格模式：本次专注结束前不能暂停")
            if settings.hapticsEnabled { Haptics.warning() }
            return false
        }
        if let endDate {
            remaining = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
        }
        stopTicking()

        NoiseEngine.shared.stop()
        Notifications.cancelPending()
        if settings.liveActivityEnabled {
            LiveActivityController.shared.pause(
                phase: phase,
                title: displayTitle,
                remaining: remaining,
                totalSeconds: totalSeconds
            )
        }
        persistState()
        return true
    }

    func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    /// 重置当前阶段（严格模式下运行时不可用）。
    func resetCurrent() {
        guard !(strictActive) else {
            showToast("严格模式：本次专注结束前不能重置")
            if settings.hapticsEnabled { Haptics.warning() }
            return
        }
        stopTicking()
        remaining = duration(for: phase)
        totalSeconds = remaining
        ScreenTimeManager.shared.deactivateShield()
        NoiseEngine.shared.stop()
        Notifications.cancelPending()
        LiveActivityController.shared.end()
        persistState()
        if settings.hapticsEnabled { Haptics.rigid() }
    }

    /// 跳过当前阶段。
    func skipPhase() {
        guard !(strictActive) else {
            showToast("严格模式：本次专注结束前不能跳过")
            if settings.hapticsEnabled { Haptics.warning() }
            return
        }
        stopTicking()
        let next = nextPhase(after: phase)
        phase = next
        totalSeconds = duration(for: next)
        remaining = totalSeconds
        ScreenTimeManager.shared.deactivateShield()
        NoiseEngine.shared.stop()
        Notifications.cancelPending()
        LiveActivityController.shared.end()
        persistState()
        if settings.hapticsEnabled { Haptics.soft() }
    }

    /// 主动放弃本次专注（对应 UI 上的长按解锁）。
    func giveUp() {
        stopTicking()
        remaining = duration(for: phase)
        totalSeconds = remaining
        ScreenTimeManager.shared.deactivateShield()
        NoiseEngine.shared.stop()
        Notifications.cancelPending()
        LiveActivityController.shared.end()
        persistState()
        showToast("已放弃本次专注")
        if settings.hapticsEnabled { Haptics.warning() }
    }

    /// 未被后台计时器覆盖的场景：App 回到前台时校正剩余时间。
    func syncAfterForeground() {
        guard isRunning, let endDate else { return }
        let left = Int(endDate.timeIntervalSinceNow.rounded(.up))
        if left <= 0 {
            remaining = 0
            finishCurrentPhase()
        } else {
            remaining = left
            startTicker()
        }
    }

    // MARK: - 设置联动

    func setNoise(_ kind: NoiseKind) {
        let newValue: NoiseKind = settings.noiseKind == kind ? .off : kind
        settings.noiseKind = newValue
        if newValue == .off {
            NoiseEngine.shared.stop()
        } else if isRunning {
            NoiseEngine.shared.start(kind: newValue, volume: settings.noiseVolume)
        }
        if settings.hapticsEnabled { Haptics.soft() }
    }

    func setNoiseVolume(_ volume: Double) {
        settings.noiseVolume = volume
        NoiseEngine.shared.setVolume(volume)
    }

    func toggleStrict() {
        settings.strictMode.toggle()
        showToast(settings.strictMode ? "严格模式已开启：专注中不能暂停" : "已关闭严格模式")
        if settings.hapticsEnabled { Haptics.soft() }
    }

    /// 时长被修改且当前未运行时，同步刷新表盘（只在时长真的变化时执行）。
    func refreshIdleTimer() {
        let signature = "\(settings.focusMinutes)-\(settings.shortBreakMinutes)-\(settings.longBreakMinutes)"
        guard signature != durationSignature else { return }
        durationSignature = signature
        guard !isRunning else { return }
        totalSeconds = duration(for: phase)
        remaining = totalSeconds
        persistState()
    }

    // MARK: - 任务

    func addTask(title: String, estimate: Int = 4, note: String = "") {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let task = FocusTask(title: trimmed, note: note, estimate: max(1, estimate))
        tasks.insert(task, at: 0)
        if activeTaskID == nil { activeTaskID = task.id }
        if settings.hapticsEnabled { Haptics.soft() }
    }

    func updateTask(_ task: FocusTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
    }

    func deleteTask(_ task: FocusTask) {
        tasks.removeAll { $0.id == task.id }
        if activeTaskID == task.id {
            activeTaskID = tasks.first(where: { !$0.isCompleted })?.id
        }
    }

    func toggleCompleted(_ task: FocusTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        if tasks[index].isCompleted, activeTaskID == task.id {
            activeTaskID = tasks.first(where: { !$0.isCompleted && $0.id != task.id })?.id
        }
        if settings.hapticsEnabled { Haptics.tap() }
    }

    func setActiveTask(_ task: FocusTask) {
        activeTaskID = activeTaskID == task.id ? nil : task.id
        if settings.hapticsEnabled { Haptics.tap() }
    }

    // MARK: - 提示

    func showToast(_ message: String) {
        let token = UUID()
        toastToken = token
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            toast = message
        }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_300_000_000)
            guard let self, self.toastToken == token else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self.toast = nil
            }
        }
    }

    // MARK: - 引擎内部

    private func duration(for phase: Phase) -> Int {
        switch phase {
        case .focus: return max(1, settings.focusMinutes) * 60
        case .shortBreak: return max(1, settings.shortBreakMinutes) * 60
        case .longBreak: return max(1, settings.longBreakMinutes) * 60
        }
    }

    private func startTicker() {
        ticker?.invalidate()
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func stopTicking() {
        ticker?.invalidate()
        ticker = nil
        isRunning = false
        endDate = nil
        applyScreenAwake()
    }

    private func tick() {
        guard isRunning, let endDate else { return }
        let left = Int(endDate.timeIntervalSinceNow.rounded(.up))
        if left <= 0 {
            remaining = 0
            finishCurrentPhase()
        } else if left != remaining {
            remaining = left
        }
    }

    private func finishCurrentPhase() {
        let finished = phase
        stopTicking()

        if finished == .focus {
            cycleCount += 1
            let minutes = max(1, totalSeconds / 60)
            records.append(
                SessionRecord(
                    finishedAt: Date(),
                    phase: .focus,
                    minutes: minutes,
                    taskTitle: activeTask?.title
                )
            )
            bumpActiveTask()
            trimRecords()
        }

        if settings.soundEnabled { SoundPlayer.shared.playChime() }
        if settings.hapticsEnabled { Haptics.success() }
        Notifications.cancelPending()

        if finished == .focus {
            ScreenTimeManager.shared.deactivateShield()
        }

        if settings.liveActivityEnabled {
            LiveActivityController.shared.finish(phase: finished, title: displayTitle)
        }
        NoiseEngine.shared.stop()

        let next = nextPhase(after: finished)
        phase = next
        totalSeconds = duration(for: next)
        remaining = totalSeconds
        persistState()

        showToast(finished == .focus ? "🍅 完成一个番茄，休息一下" : "休息结束，开始下一个番茄")

        let autoStart = next == .focus ? settings.autoStartFocus : settings.autoStartBreaks
        if autoStart {
            start()
        }
    }

    private func finishExpiredSession(at date: Date) {
        let finished = phase
        if finished == .focus {
            cycleCount += 1
            let minutes = max(1, totalSeconds / 60)
            records.append(
                SessionRecord(finishedAt: date, phase: .focus, minutes: minutes, taskTitle: activeTask?.title)
            )
            bumpActiveTask()
            trimRecords()
        }
        stopTickerOnly()
        phase = nextPhase(after: finished)
        totalSeconds = duration(for: phase)
        remaining = totalSeconds
        ScreenTimeManager.shared.deactivateShield()
        persistState()
    }

    private func stopTickerOnly() {
        ticker?.invalidate()
        ticker = nil
        isRunning = false
        endDate = nil
    }

    private func nextPhase(after finished: Phase) -> Phase {
        guard finished == .focus else { return .focus }
        let target = max(1, settings.sessionsBeforeLongBreak)
        let needsLongBreak = cycleCount > 0 && cycleCount % target == 0
        return needsLongBreak ? .longBreak : .shortBreak
    }

    private func bumpActiveTask() {
        guard let activeTaskID, let index = tasks.firstIndex(where: { $0.id == activeTaskID }) else { return }
        tasks[index].done += 1
    }

    private func trimRecords() {
        if records.count > 500 {
            records = Array(records.suffix(500))
        }
    }

    private func activateBlockingIfNeeded() {
        guard phase == .focus else { return }
        let manager = ScreenTimeManager.shared
        guard manager.isAuthorized, manager.selectedCount > 0 else { return }
        manager.activateShield()
    }

    private func applyScreenAwake() {
        UIApplication.shared.isIdleTimerDisabled = settings.keepScreenAwake && isRunning
    }

    // MARK: - 持久化

    private func persistState() {
        let defaults = UserDefaults.standard
        defaults.set(isRunning, forKey: Keys.isRunning)
        defaults.set(phase.rawValue, forKey: Keys.phase)
        defaults.set(remaining, forKey: Keys.remaining)
        defaults.set(totalSeconds, forKey: Keys.total)
        if let endDate {
            defaults.set(endDate, forKey: Keys.endDate)
        } else {
            defaults.removeObject(forKey: Keys.endDate)
        }
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func restore<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
