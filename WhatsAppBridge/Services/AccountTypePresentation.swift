import Foundation

enum AccountTypePresentation {
    static func title(
        _ value: String?
    ) -> String {
        switch value?
            .lowercased() {

        case "business":
            return "WhatsApp Business"

        case "regular",
             "personal":
            return "WhatsApp"

        default:
            return "WhatsApp"
        }
    }

    static func icon(
        _ value: String?
    ) -> String {
        switch value?
            .lowercased() {

        case "business":
            return "briefcase.fill"

        default:
            return "message.fill"
        }
    }
}
