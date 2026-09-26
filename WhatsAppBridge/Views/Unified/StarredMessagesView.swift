import SwiftUI

struct StarredMessagesView: View {
    let messages: [Message]

    @ObservedObject
    private var stars = StarredMessageStore.shared

    private var starred: [Message] {
        messages.filter {
            stars.contains($0)
        }
    }

    var body: some View {
        List {
            if starred.isEmpty {
                ContentUnavailableView(
                    "No Starred Messages",
                    systemImage: "star"
                )
            }

            ForEach(starred) { message in
                VStack(alignment: .leading, spacing: 6) {
                    if !message.text.isEmpty {
                        Text(message.text)
                            .font(.body)
                            .lineLimit(5)
                    } else {
                        Label(
                            message.type.capitalized,
                            systemImage: icon(message)
                        )
                    }

                    Text(date(message))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Starred Messages")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func icon(_ message: Message) -> String {
        switch message.type {
        case "image": return "photo"
        case "video": return "video"
        case "voice", "audio": return "waveform"
        case "document": return "doc"
        default: return "message"
        }
    }

    private func date(_ message: Message) -> String {
        Date(
            timeIntervalSince1970:
                TimeInterval(message.createdAt)
        )
        .formatted(date: .abbreviated, time: .shortened)
    }
}
