import Foundation

enum IsraeliPhonePresentation {
    // A presentation rule, never a routing/JID rule. Do not infer country from
    // arbitrary digits (especially a WhatsApp LID).
    static func copyValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains("@") else { return trimmed }
        let compact = trimmed.filter { !" -().\u{00a0}".contains($0) }
        let rest: Substring
        if compact.hasPrefix("+972") { rest = compact.dropFirst(4) }
        else if compact.hasPrefix("00972") { rest = compact.dropFirst(5) }
        else { return trimmed }
        guard !rest.isEmpty, rest.utf8.allSatisfy({ (48...57).contains($0) }) else { return trimmed }
        // The server-resolved number is the source of truth; preserve its digits.
        return rest.hasPrefix("0") ? String(rest) : "0" + rest
    }
}
