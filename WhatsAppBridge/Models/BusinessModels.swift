import Foundation

struct BusinessCustomerMeta: Codable {
    let jid: String
    var label: String
    var note: String
}

struct BusinessQuickReply:
    Codable,
    Identifiable
{
    let id: Int64
    let shortcut: String
    let message: String
}
