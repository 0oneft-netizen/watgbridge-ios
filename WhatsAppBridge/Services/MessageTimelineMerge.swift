import Foundation

enum MessageTimelineMerge {
    static func apply(_ batch: MessageSyncBatch, to existing: [Message]) -> [Message] {
        if !batch.reset && batch.messages.isEmpty && batch.removed.isEmpty { return existing }
        let removed = Set(batch.removed)
        var rows = Dictionary(uniqueKeysWithValues: (batch.reset ? [] : existing).filter { !removed.contains($0.id) }.map { ($0.id, $0) })
        for message in batch.messages { rows[message.id] = message }
        return rows.values.sorted {
            $0.createdAt == $1.createdAt ? $0.id < $1.id : $0.createdAt < $1.createdAt
        }
    }
}
