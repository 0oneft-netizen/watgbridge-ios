import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationManager:
    NSObject,
    UNUserNotificationCenterDelegate {

    static let shared =
        NotificationManager()

    private override init() {
        super.init()

        UNUserNotificationCenter
            .current()
            .delegate = self
    }

    func requestPermission() async {
        do {
            let granted =
                try await UNUserNotificationCenter
                    .current()
                    .requestAuthorization(
                        options: [
                            .alert,
                            .badge,
                            .sound
                        ]
                    )

            if granted {
                UIApplication.shared
                    .registerForRemoteNotifications()
            }
        } catch {
        }
    }

    func setBadgeCount(
        _ count: Int
    ) async {
        do {
            try await UNUserNotificationCenter
                .current()
                .setBadgeCount(
                    max(0, count)
                )
        } catch {
        }
    }

    nonisolated func userNotificationCenter(
        _ center:
            UNUserNotificationCenter,
        willPresent notification:
            UNNotification
    ) async
        -> UNNotificationPresentationOptions {

        [
            .banner,
            .sound,
            .badge
        ]
    }
}
