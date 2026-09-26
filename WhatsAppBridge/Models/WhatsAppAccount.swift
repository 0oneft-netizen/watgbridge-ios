import Foundation

struct WhatsAppAccount:
    Codable,
    Identifiable
{
    let id: String
    let displayName: String
    let phone: String
    let status: String
    let isPrimary: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case phone
        case status
        case isPrimary = "is_primary"
    }
}
