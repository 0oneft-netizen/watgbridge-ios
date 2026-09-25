import Foundation

struct WhatsAppAccountStatus: Codable {
    let id: String?
    let accountID: String?
    let status: String
    let connected: Bool?
    let phone: String?
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case accountID = "account_id"
        case status
        case connected
        case phone
        case displayName = "display_name"
    }
}

struct WhatsAppQRResponse: Codable {
    let accountID: String?
    let qr: String?
    let code: String?
    let status: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accountID = "account_id"
        case qr
        case code
        case status
        case expiresIn = "expires_in"
    }

    var qrValue: String? {
        if let qr, !qr.isEmpty {
            return qr
        }

        if let code, !code.isEmpty {
            return code
        }

        return nil
    }
}
