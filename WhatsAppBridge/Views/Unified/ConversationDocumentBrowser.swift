import SwiftUI

struct ConversationDocumentBrowser: View {
    let messages: [Message]

    var body: some View {
        List {
            if messages.isEmpty {
                ContentUnavailableView(
                    "No Documents",
                    systemImage: "doc"
                )
            }

            ForEach(messages) { message in
                HStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        Text(
                            message.fileName
                            ?? "Document"
                        )
                        .font(.body.weight(.medium))
                        .lineLimit(2)

                        if let mime =
                            message.mimeType {
                            Text(mime)
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.inline)
    }
}
