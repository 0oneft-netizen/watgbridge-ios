import SwiftUI

struct ConversationDocumentBrowser: View {
    let messages: [Message]

    private var documents: [Message] {
        messages.filter {
            $0.type.lowercased()
                == "document"
            &&
            !MessageMediaPolicy
                .isViewOnce($0)
        }
    }

    var body: some View {
        List {
            if documents.isEmpty {
                ContentUnavailableView(
                    "No Documents",
                    systemImage: "doc",
                    description:
                        Text(
                            "Documents shared in this conversation appear here."
                        )
                )
            } else {
                ForEach(documents) {
                    message in

                    documentRow(message)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .tint(
            AppVisualDesign.accent
        )
    }

    private func documentRow(
        _ message: Message
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 9,
                    style: .continuous
                )
                .fill(
                    AppVisualDesign
                        .accent
                        .opacity(0.11)
                )

                Image(
                    systemName:
                        "doc.fill"
                )
                .font(
                    .system(
                        size: 20,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    AppVisualDesign.accent
                )
            }
            .frame(
                width: 44,
                height: 44
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(
                    message.fileName
                    ?? "Document"
                )
                .font(
                    .body.weight(
                        .medium
                    )
                )
                .foregroundStyle(
                    .primary
                )
                .lineLimit(2)

                HStack(spacing: 5) {
                    if let mime =
                        message.mimeType,
                       !mime.isEmpty {

                        Text(
                            shortMime(mime)
                        )
                    }

                    if message.createdAt > 0 {
                        Text("•")

                        Text(
                            formattedDate(
                                message.createdAt
                            )
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
                .lineLimit(1)
            }

            Spacer(minLength: 4)

            Image(
                systemName:
                    "chevron.right"
            )
            .font(.caption.weight(.bold))
            .foregroundStyle(
                Color.secondary
                    .opacity(0.5)
            )
        }
        .padding(.vertical, 5)
    }

    private func shortMime(
        _ mime: String
    ) -> String {
        let value =
            mime
                .split(separator: "/")
                .last
                .map(String.init)
                ?? mime

        return value
            .replacingOccurrences(
                of: "vnd.openxmlformats-officedocument.",
                with: ""
            )
            .uppercased()
    }

    private func formattedDate(
        _ raw: Int64
    ) -> String {
        let seconds =
            raw > 10_000_000_000
            ? Double(raw) / 1000
            : Double(raw)

        return Date(
            timeIntervalSince1970:
                seconds
        )
        .formatted(
            date: .abbreviated,
            time: .omitted
        )
    }
}
