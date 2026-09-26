import SwiftUI

struct UnsupportedMessageView: View {
    let message:
        Message

    var body: some View {
        Label(
            "Unsupported message",
            systemImage:
                "questionmark.bubble"
        )
        .font(.caption)
        .foregroundStyle(
            .secondary
        )
        .padding(
            .vertical,
            4
        )
    }
}
