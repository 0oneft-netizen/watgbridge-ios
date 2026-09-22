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
            print(
                "notification permission:",
                error
            )
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

    func showIncoming(
        title: String,
        body: String
    ) async {

        let content =
            UNMutableNotificationContent()

        content.title = title

        content.body =
            body.isEmpty
            ? "New WhatsApp message"
            : body

        content.sound = .default

        let request =
            UNNotificationRequest(
                identifier:
                    UUID().uuidString,
                content: content,
                trigger: nil
            )

        do {
            try await UNUserNotificationCenter
                .current()
                .add(request)
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
            .badge,
            .list
        ]
    }
}
