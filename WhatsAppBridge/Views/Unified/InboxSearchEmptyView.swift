import SwiftUI

struct InboxSearchEmptyView: View {
    let query: String

    var body: some View {
        ContentUnavailableView(
            "No chats found",
            systemImage: "magnifyingglass",
            description:
                Text(
                    "No customer matches “\(query)”."
                )
        )
    }
}
