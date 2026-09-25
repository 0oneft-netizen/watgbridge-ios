import Foundation

struct WhatsAppAccount:
    Codable,
    Identifiable,
    Hashable
{
    let id: String

    let displayName: String
    let phone: String
    let jid: String
    let status: String
    let isDefault: Bool?

    enum CodingKeys:
        String,
        CodingKey
    {
        case id

        case displayName =
            "display_name"

        case phone
        case jid
        case status

        case isDefault =
            "is_default"
    }

    var connected: Bool {
        status == "connected"
    }
}

struct WhatsAppAccountStatus:
    Codable
{
    let id: String
    let displayName: String
    let phone: String
    let jid: String
    let status: String

    enum CodingKeys:
        String,
        CodingKey
    {
        case id

        case displayName =
            "display_name"

        case phone
        case jid
        case status
    }
}

struct WhatsAppQRResponse:
    Codable
{
    let id: String
    let status: String
    let qr: String
}
