import Foundation

struct SessionIdentity: Identifiable, Hashable {
    let id: String
    let name: String
    let phone: String
    let jid: String
    let status: String
    let accountType: String

    var effectiveName: String {
        let value = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !value.isEmpty {
            return value
        }

        if !phone.isEmpty {
            return phone
        }

        return "WhatsApp Account"
    }

    var formattedPhone: String {
        guard !phone.isEmpty else {
            return "Unknown number"
        }

        if phone.hasPrefix("+") {
            return phone
        }

        return "+" + phone
    }

    var accountTypeLabel: String {
        switch accountType.lowercased() {
        case "business":
            return "WhatsApp Business"
        case "regular", "personal", "consumer":
            return "WhatsApp"
        default:
            return accountType.isEmpty
                ? "WhatsApp"
                : accountType
        }
    }

    var systemImage: String {
        accountType.lowercased() == "business"
            ? "briefcase.fill"
            : "message.fill"
    }

    var isConnected: Bool {
        status.lowercased() == "connected"
    }

    var routeLabel: String {
        "\(effectiveName) • \(formattedPhone)"
    }
}
