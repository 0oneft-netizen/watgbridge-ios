import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: Int64

    let messageID: String
    let accountID: String?
    let chatJID: String
    let senderJID: String

    let text: String
    let type: String

    let fromMe: Bool
    let createdAt: Int64

    let campaignReferral: CampaignReferral?
    let campaignImageURL: String?

    let mediaPath: String?
    let mimeType: String?
    let fileName: String?

    let replyToID: String?
    let reaction: String?

    let deletedRemote: Bool?
    let deletedLocal: Bool?
    let deliveryState: String?

    enum CodingKeys: String, CodingKey {
        case id
        case messageID = "message_id"
        case accountID = "account_id"
        case chatJID = "chat_jid"
        case senderJID = "sender_jid"

        case text
        case type

        case fromMe = "from_me"
        case createdAt = "created_at"

        case campaignReferral = "campaign_referral"
        case campaignImageURL = "campaign_image_url"

        case mediaPath = "media_path"
        case mimeType = "mime_type"
        case fileName = "file_name"

        case replyToID = "reply_to_id"
        case reaction

        case deletedRemote = "deleted_remote"
        case deletedLocal = "deleted_local"
        case deliveryState = "delivery_state"
    }
}

// Field names match WhatsApp protobuf JSON.
struct CampaignReferral: Codable, Equatable {
    let title: String?
    let body: String?
    let sourceApp: String?
    let sourceType: String?
    let sourceID: String?
    let sourceURL: String?
    let originalImageURL: String?
    let thumbnailURL: String?
    let thumbnail: String?
    let mediaURL: String?
    let adPreviewURL: String?
    let wtwaWebsiteURL: String?
    let ctwaClid: String?
    let ref: String?
    let showAdAttribution: Bool?
    let renderLargerThumbnail: Bool?
}
