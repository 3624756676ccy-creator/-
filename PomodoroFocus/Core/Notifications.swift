import Foundation
import UserNotifications

enum Notifications {
    private static let endIdentifier = "pomodoro.session.end"

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleEnd(at date: Date, phase: Phase) {
        cancelPending()
        let interval = date.timeIntervalSinceNow
        guard interval > 1 else { return }

        let content = UNMutableNotificationContent()
        if phase == .focus {
            content.title = "🍅 专注完成"
            content.body = "起来活动一下，喝口水吧。"
        } else {
            content.title = "休息结束"
            content.body = "回来继续下一个番茄。"
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: endIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    static func cancelPending() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [endIdentifier])
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: [endIdentifier])
    }
}
