import Foundation

enum CacheMaintenance {
    static func removeFilesOlderThan(days: Int = 30) {
        Task { @MainActor in
            let keys = StarredMessageStore.shared.keys.union(UltraChatStore.shared.pins.map { ($0.accountID ?? "default") + "|" + $0.messageID })
            _ = try? await MediaCache.shared.cleanStorage(workspace: UserWorkspace.id, protectedKeys: keys, olderThan: Date().addingTimeInterval(-Double(abs(days)) * 86400))
        }
    }
    static func removeAllMediaCache() {
        Task { @MainActor in
            let keys = StarredMessageStore.shared.keys.union(UltraChatStore.shared.pins.map { ($0.accountID ?? "default") + "|" + $0.messageID })
            _ = try? await MediaCache.shared.cleanStorage(workspace: UserWorkspace.id, protectedKeys: keys)
        }
    }
}
