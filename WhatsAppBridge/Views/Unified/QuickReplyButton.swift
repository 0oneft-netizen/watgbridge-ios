import SwiftUI

struct QuickReplyButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(
                systemName:
                    "bolt.fill"
            )
            .font(.body)
            .frame(
                width: 34,
                height: 34
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Quick replies"
        )
    }
}
