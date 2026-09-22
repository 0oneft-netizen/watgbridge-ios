import Foundation

struct Conversation: Identifiable, Codable {
    var id: String { jid }

    let jid: String
    let name: String
}
