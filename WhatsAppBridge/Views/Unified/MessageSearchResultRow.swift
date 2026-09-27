import SwiftUI

struct MessageSearchResultRow: View {
    let message: Message
    let sessionName: String

    private var dateText: String {
        let raw =
            Double(message.createdAt)

        let seconds =
            raw > 10_000_000_000
            ? raw / 1000
            : raw

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

    private var fallbackText: String {
        switch message.type.lowercased() {
        case "image":
            return "Photo"
        case "video", "video_note", "ptv":
            return "Video"
        case "gif":
            return "GIF"
        case "voice", "audio":
            return "Voice message"
        case "document":
            return message.fileName ?? "Document"
        case "sticker":
            return "Sticker"
        default:
            return "Message"
        }
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
                    ? fallbackText
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
