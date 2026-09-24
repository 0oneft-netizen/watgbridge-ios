import Foundation
import UIKit
import UserNotifications

@MainActor
final class NotificationManager:
    NSObject,
    UNUserNotificationCenterDelegate
{
    static let shared = NotificationManager()

    private override init() {
        super.init()

        AppSettings.registerDefaults()

        UNUserNotificationCenter.current().delegate = self

        configureCategories()
    }

    private func configureCategories() {
        let openAction = UNNotificationAction(
            identifier: "OPEN_CHAT",
            title: "Open",
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: "WHATSAPP_MESSAGE",
            actions: [openAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current()
            .setNotificationCategories([category])
    }

    func requestPermission() async {
        do {
            _ = try await
                UNUserNotificationCenter.current()
                .requestAuthorization(
                    options: [
                        .alert,
                        .sound,
                        .badge
                    ]
                )
        } catch {
            print(
                "Notification permission error:",
                error
            )
        }
    }

    func registerForPushNotifications() {
        UIApplication.shared
            .registerForRemoteNotifications()
    }

    func setBadgeCount(
        _ count: Int
    ) async {
        guard AppSettings.badge else {
            try? await
                UNUserNotificationCenter.current()
                .setBadgeCount(0)

            return
        }

        try? await
            UNUserNotificationCenter.current()
            .setBadgeCount(count)
    }

    func showIncoming(
        title: String,
        body: String
    ) async {
        guard AppSettings.notifications else {
            return
        }

        let content =
            UNMutableNotificationContent()

        content.title = title

        if AppSettings.previews {
            content.body = body
        } else {
            content.body = "New message"
        }

        if AppSettings.sound {
            content.sound = .default
        }

        content.categoryIdentifier =
            "WHATSAPP_MESSAGE"

        let request =
            UNNotificationRequest(
                identifier:
                    UUID().uuidString,
                content: content,
                trigger: nil
            )

        do {
            try await
                UNUserNotificationCenter.current()
                .add(request)
        } catch {
            print(
                "Notification error:",
                error
            )
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        var options:
            UNNotificationPresentationOptions =
                [.banner, .list]

        if AppSettings.sound {
            options.insert(.sound)
        }

        if AppSettings.badge {
            options.insert(.badge)
        }

        return options
    }
}
