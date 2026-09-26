import SwiftUI

struct MessageDeliveryIndicator: View {
    let message: Message

    var body: some View {
        if message.fromMe {
            Image(
                systemName: "checkmark"
            )
            .font(
                .system(
                    size: 9,
                    weight: .bold
                )
            )
            .foregroundStyle(.secondary)
            .accessibilityLabel(
                "Sent"
            )
        }
    }
}
