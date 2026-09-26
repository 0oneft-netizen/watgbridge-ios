import Foundation
import UserNotifications

actor FollowUpNotificationService {
    static let shared =
        FollowUpNotificationService()

    func requestPermission()
        async -> Bool {

        do {
            return try await
                UNUserNotificationCenter
                    .current()
                    .requestAuthorization(
                        options:
                            [
                                .alert,
                                .sound,
                                .badge
                            ]
                    )
        } catch {
            return false
        }
    }

    func schedule(
        conversation:
            Conversation,
        customerName:
            String,
        followUp:
            CustomerFollowUp
    ) async {

        guard
            !followUp.completed,
            followUp.dueAt >
                Date()
        else {
            return
        }

        let content =
            UNMutableNotificationContent()

        content.title =
            "Follow Up"

        content.body =
            followUp.note.isEmpty
            ?
            customerName
            :
            customerName
            + " — "
            + followUp.note

        content.sound =
            .default

        let interval =
            max(
                1,
                followUp
                    .dueAt
                    .timeIntervalSinceNow
            )

        let trigger =
            UNTimeIntervalNotificationTrigger(
                timeInterval:
                    interval,
                repeats:
                    false
            )

        let id =
            identifier(
                conversation
            )

        let request =
            UNNotificationRequest(
                identifier:
                    id,
                content:
                    content,
                trigger:
                    trigger
            )

        try? await
            UNUserNotificationCenter
                .current()
                .add(request)
    }

    func cancel(
        _ conversation:
            Conversation
    ) {
        UNUserNotificationCenter
            .current()
            .removePendingNotificationRequests(
                withIdentifiers:
                    [
                        identifier(
                            conversation
                        )
                    ]
            )
    }

    private func identifier(
        _ conversation:
            Conversation
    ) -> String {
        "followup."
        +
        (conversation.accountID
            ?? "default")
        +
        "."
        +
        conversation.jid
    }
}
