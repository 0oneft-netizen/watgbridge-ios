import Foundation

actor RealtimeRefreshCoordinator {
    static let shared =
        RealtimeRefreshCoordinator()

    private var pending:
        [String: Task<Void, Never>] = [:]

    func schedule(
        accountID: String,
        chatJID: String,
        action:
            @escaping @MainActor
            () async -> Void
    ) {
        let key =
            accountID + "|" + chatJID

        pending[key]?.cancel()

        pending[key] = Task {
            try? await Task.sleep(
                for: .milliseconds(180)
            )

            guard !Task.isCancelled else {
                return
            }

            await action()

            await self.clear(key)
        }
    }

    private func clear(
        _ key: String
    ) {
        pending[key] = nil
    }
}
