//
//  NotificationManager.swift
//  Odomap
//

import UserNotifications

/// ローカル通知（熱中症警告など）の送受信を担当。リモート通知・CloudKit連携は使用しない。
enum NotificationManager {
    static func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func postHeatWarning(temperatureCelsius: Double) {
        let content = UNMutableNotificationContent()
        content.title = "熱中症に注意"
        content.body = String(format: "気温が%.0f℃です。こまめに水分補給と休憩を取りましょう。", temperatureCelsius)
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

/// フォアグラウンド中もローカル通知をバナー表示させるための delegate
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    // UserNotificationsもメインスレッド以外からdelegateを呼ぶことがあるためnonisolatedにする。
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
