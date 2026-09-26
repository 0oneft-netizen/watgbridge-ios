import Foundation

actor OutboxRetryCoordinator {
    static let shared =
        OutboxRetryCoordinator()

    private var running =
        Set<String>()

    func run(
        accountID: String,
        chatJID: String,
        operation:
            @escaping @MainActor
            (OutboxTextMessage)
            async throws -> Void
    ) async {
        let route =
            accountID + "|" + chatJID

        guard
            !running.contains(route)
        else {
            return
        }

        running.insert(route)

        defer {
            running.remove(route)
        }

        let messages =
            await MainActor.run {
                PersistentOutbox
                    .shared
                    .messages(
                        accountID:
                            accountID,
                        chatJID:
                            chatJID
                    )
            }

        for message in messages {
            guard
                message.attempts < 5
            else {
                continue
            }

            await MainActor.run {
                PersistentOutbox
                    .shared
                    .markAttempt(
                        id: message.id
                    )
            }

            do {
                try await operation(
                    message
                )

                await MainActor.run {
                    PersistentOutbox
                        .shared
                        .remove(
                            id:
                                message.id
                        )
                }
            } catch {
                break
            }
        }
    }
}
