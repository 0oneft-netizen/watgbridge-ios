import SwiftUI

struct MessageSearchResultRow: View {
    let message: Message
    let sessionName: String

    private var dateText: String {
        let raw =
            message.createdAt

        let seconds =
            raw > 10_000_000_000
            ? Double(raw) / 1000
            : Double(raw)

        guard seconds > 0 else {
            return ""
        }

        return Date(
            timeIntervalSince1970:
                seconds
        )
        .formatted(
            date: .abbreviated,
            time: .shortened
        )
    }

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 11
        ) {
            Image(
                systemName:
                    message.fromMe
                    ? "arrow.up.circle.fill"
                    : "arrow.down.circle.fill"
            )
            .foregroundStyle(
                AppVisualDesign.accent
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(
                    message.text.isEmpty
                    ? MessagePresentation
                        .fallbackText(
                            for: message
                        )
                    : message.text
                )
                .font(.body)
                .lineLimit(3)

                HStack(spacing: 5) {
                    if !sessionName.isEmpty {
                        Text(sessionName)
                    }

                    if !sessionName.isEmpty
                        && !dateText.isEmpty {
                        Text("•")
                    }

                    Text(dateText)
                }
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer()
        }
        .padding(.vertical, 5)
    }
}
