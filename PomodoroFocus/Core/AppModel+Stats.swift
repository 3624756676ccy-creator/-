import Foundation

/// 柱状图用的单日数据。
struct DayStat: Identifiable, Hashable {
    var id: Date { date }
    var date: Date
    var label: String
    var count: Int
}

/// 任务排行行数据。
struct TaskRank: Identifiable, Hashable {
    var id: UUID
    var title: String
    var done: Int
}

extension AppModel {

    var focusRecords: [SessionRecord] {
        records.filter { $0.phase == .focus }
    }

    var todayRecords: [SessionRecord] {
        let calendar = Calendar.current
        return focusRecords.filter { calendar.isDateInToday($0.finishedAt) }
    }

    var todayFocusCount: Int { todayRecords.count }

    var todayFocusMinutes: Int { todayRecords.reduce(0) { $0 + $1.minutes } }

    var totalFocusCount: Int { focusRecords.count }

    var totalFocusMinutes: Int { focusRecords.reduce(0) { $0 + $1.minutes } }

    /// 连续打卡天数（今天或昨天有记录即可延续）。
    var streakDays: Int {
        let calendar = Calendar.current
        let days = Set(focusRecords.map { calendar.startOfDay(for: $0.finishedAt) })
        guard !days.isEmpty else { return 0 }

        var cursor = calendar.startOfDay(for: Date())
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }

        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    var todayGoalRemaining: Int {
        max(0, settings.dailyGoal - todayFocusCount)
    }

    var todayFocusText: String {
        if todayFocusMinutes >= 60 {
            let hours = Double(todayFocusMinutes) / 60.0
            return String(format: "%.1f", hours)
        }
        return "\(todayFocusMinutes)"
    }

    var todayFocusUnit: String {
        todayFocusMinutes >= 60 ? "小时" : "分钟"
    }

    /// 最近 N 天的番茄数。
    func weekSeries(days: Int = 7) -> [DayStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [DayStat] = []
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE"

        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let count = focusRecords.filter { calendar.isDate($0.finishedAt, inSameDayAs: day) }.count
            let label = offset == 0 ? "今天" : formatter.string(from: day)
            result.append(DayStat(date: day, label: label, count: count))
        }
        return result
    }

    /// 按任务标题聚合的番茄排行。
    func taskRanking(limit: Int = 5) -> [TaskRank] {
        var buckets: [String: Int] = [:]
        for record in focusRecords {
            guard let title = record.taskTitle, !title.isEmpty else { continue }
            buckets[title, default: 0] += 1
        }
        return buckets
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { TaskRank(id: UUID(), title: $0.key, done: $0.value) }
    }

    /// 今日 / 本周汇总文案。
    var weeklySummary: String {
        let series = weekSeries()
        let total = series.reduce(0) { $0 + $1.count }
        let best = series.max { $0.count < $1.count }
        if total == 0 { return "本周还没有番茄，从第一个开始吧。" }
        return "本周共完成 \(total) 个番茄，最佳是\(best?.label ?? "今天")（\(best?.count ?? 0) 个）。"
    }
}
