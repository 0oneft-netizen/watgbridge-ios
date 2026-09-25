import Foundation

struct CreateWhatsAppAccountResponse:
    Codable
{
    let id: String
    let status: String?
    let qr: String?
    let error: String?
    let accountType: String?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case qr
        case error
        case accountType = "account_type"
    }
}
