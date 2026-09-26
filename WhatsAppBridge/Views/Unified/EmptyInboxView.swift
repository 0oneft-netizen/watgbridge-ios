import SwiftUI

struct EmptyInboxView: View {
    let searching:
        Bool

    var body: some View {
        ContentUnavailableView(
            searching
            ? "No Results"
            : "No Conversations",
            systemImage:
                searching
                ? "magnifyingglass"
                : "message",
            description:
                Text(
                    searching
                    ? "Try another name, phone number, note or label."
                    : "New conversations will appear here."
                )
        )
    }
}
