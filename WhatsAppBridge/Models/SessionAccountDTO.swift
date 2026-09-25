import Foundation

struct SessionAccountDTO: Codable, Identifiable {
    let id: String
    let displayName: String?
    let phone: String?
    let jid: String?
    let status: String?
    let accountType: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case phone
        case jid
        case status
        case accountType = "account_type"
    }
}
