import Foundation
import UIKit
import UserNotifications

extension Notification.Name {
    static let openNotificationConversation =
        Notification.Name("openNotificationConversation")
}

@MainActor
final class NotificationManager:
    NSObject,
    UNUserNotificationCenterDelegate
{
    static let shared = NotificationManager()

    private enum ID {
        static let category = "WHATSAPP_MESSAGE"
        static let open = "OPEN_CHAT"
        static let reply = "REPLY_MESSAGE"
        static let markRead = "MARK_READ"
    }

    private override init() {
        super.init()

        AppSettings.registerDefaults()

        UNUserNotificationCenter.current().delegate = self

        configureCategories()
    }

    private func configureCategories() {
        let reply =
            UNTextInputNotificationAction(
                identifier: ID.reply,
                title: "Reply",
                options: [],
                textInputButtonTitle: "Send",
                textInputPlaceholder: "Message"
            )

        let markRead =
            UNNotificationAction(
                identifier: ID.markRead,
                title: "Mark as Read",
                options: []
            )

        let open =
            UNNotificationAction(
                identifier: ID.open,
                title: "Open",
                options: [.foreground]
            )

        let category =
            UNNotificationCategory(
                identifier: ID.category,
                actions: [
                    reply,
                    markRead,
                    open
                ],
                intentIdentifiers: [],
                options: [.customDismissAction]
            )

        UNUserNotificationCenter.current()
            .setNotificationCategories([
                category
            ])
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
                .setBadgeCount(
                    max(0, count)
                )
    }

    func showIncoming(
        message: RealtimeIncomingMessage,
        title: String,
        badge: Int
    ) async {
        guard AppSettings.notifications else {
            return
        }

        let content =
            UNMutableNotificationContent()

        content.title =
            title.isEmpty
            ? "WhatsApp"
            : title

        if AppSettings.previews {
            content.body =
                message.notificationBody
        } else {
            content.body =
                "New message"
        }

        if AppSettings.sound {
            content.sound = .default
        }

        if AppSettings.badge {
            content.badge =
                NSNumber(
                    value: max(0, badge)
                )
        }

        content.categoryIdentifier =
            ID.category

        // Notifications from the same account/chat
        // are grouped together by iOS.
        content.threadIdentifier =
            "\(message.account_id)|\(message.chat_jid)"

        content.userInfo = [
            "account_id":
                message.account_id,
            "chat_jid":
                message.chat_jid,
            "message_id":
                String(message.id),
            "message_type":
                message.message_type
        ]

        let request =
            UNNotificationRequest(
                identifier:
                    message.notificationIdentifier,
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

    private func routeToChat(
        accountID: String,
        chatJID: String
    ) {
        NotificationCenter.default.post(
            name:
                .openNotificationConversation,
            object: nil,
            userInfo: [
                "account_id": accountID,
                "chat_jid": chatJID
            ]
        )
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification:
            UNNotification
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

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response:
            UNNotificationResponse
    ) async {
        let info =
            response.notification
                .request
                .content
                .userInfo

        guard
            let accountID =
                info["account_id"] as? String,
            let chatJID =
                info["chat_jid"] as? String
        else {
            return
        }

        switch response.actionIdentifier {

        case ID.reply:
            guard
                let textResponse =
                    response
                        as? UNTextInputNotificationResponse
            else {
                return
            }

            let text =
                textResponse.userText
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            guard !text.isEmpty else {
                return
            }

            try? await APIClient.shared
                .sendMessage(
                    chatJID: chatJID,
                    text: text,
                    accountID: accountID
                )

        case ID.markRead:
            try? await APIClient.shared
                .markRead(
                    chatJID: chatJID,
                    accountID: accountID
                )

        case ID.open,
             UNNotificationDefaultActionIdentifier:
            await MainActor.run {
                self.routeToChat(
                    accountID: accountID,
                    chatJID: chatJID
                )
            }

        default:
            break
        }
    }
}
