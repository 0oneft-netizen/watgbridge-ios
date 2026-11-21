import Foundation

enum NewChatPhone {
    static func digits(_ input: String) -> String? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.unicodeScalars.allSatisfy({ "+0123456789 -().\u{00a0}".unicodeScalars.contains($0) }) else { return nil }
        var compact = value.filter { !" -().\u{00a0}".contains($0) }
        if compact.hasPrefix("00") { compact = "+" + compact.dropFirst(2) }
        if compact.hasPrefix("0") && !compact.hasPrefix("+") {
            guard compact.range(of: #"^0(?:5[0-9]{8}|[23489][0-9]{7})$"#, options: .regularExpression) != nil else { return nil }
            compact = "+972" + compact.dropFirst()
        } else if compact.hasPrefix("972") { compact = "+" + compact }
        guard compact.hasPrefix("+") else { return nil }
        let number = String(compact.dropFirst())
        guard (8...15).contains(number.count), number.first != "0", number.utf8.allSatisfy({ (48...57).contains($0) }) else { return nil }
        return number
    }
}
