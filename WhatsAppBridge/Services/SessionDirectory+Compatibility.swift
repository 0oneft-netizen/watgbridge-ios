import Foundation

@MainActor
extension SessionDirectory {
    var accounts: [SessionIdentity] {
        sessions.values.sorted {
            $0.effectiveName.localizedCaseInsensitiveCompare(
                $1.effectiveName
            ) == .orderedAscending
        }
    }
}
