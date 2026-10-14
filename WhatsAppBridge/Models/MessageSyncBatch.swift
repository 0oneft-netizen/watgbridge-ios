import Foundation

struct MessageSyncBatch: Decodable {
    let cursor: Int64
    let reset: Bool
    let messages: [Message]
    let removed: [Int64]
}
