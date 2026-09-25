import SwiftUI

struct AccountBadgeView: View {
    let accountID: String?

    private var title: String {
        guard
            let accountID,
            !accountID.isEmpty
        else {
            return "WA"
        }

        if accountID == "primary" {
            return "WA 1"
        }

        return accountID
    }

    var body: some View {
        Text(title)
            .font(.caption2.bold())
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(
                        Color.secondary
                            .opacity(0.14)
                    )
            )
    }
}
