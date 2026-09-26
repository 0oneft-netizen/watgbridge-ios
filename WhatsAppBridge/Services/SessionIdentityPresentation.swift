import Foundation

@MainActor
enum SessionIdentityPresentation {
    static func name(
        accountID:
            String?
    ) -> String {

        SessionDirectory
            .shared
            .name(
                for:
                    accountID
                    ?? "default"
            )
    }
}
