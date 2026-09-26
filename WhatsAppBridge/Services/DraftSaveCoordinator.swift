import Foundation

actor DraftSaveCoordinator {
    static let shared =
        DraftSaveCoordinator()

    private var tasks:
        [String: Task<Void, Never>] = [:]

    func schedule(
        text: String,
        accountID: String,
        chatJID: String
    ) {
        let key =
            accountID + "|" + chatJID

        tasks[key]?.cancel()

        tasks[key] = Task {
            try? await Task.sleep(
                for: .milliseconds(250)
            )

            guard
                !Task.isCancelled
            else {
                return
            }

            await MainActor.run {
                ChatDraftStore
                    .shared
                    .save(
                        text,
                        accountID:
                            accountID,
                        chatJID:
                            chatJID
                    )
            }

            await clear(key)
        }
    }

    private func clear(
        _ key: String
    ) {
        tasks[key] = nil
    }
}
