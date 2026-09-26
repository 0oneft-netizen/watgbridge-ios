import SwiftUI

struct RichConversationLinksView: View {
    let messages: [Message]

    private var links: [URL] {
        MessageContentDetector.links(
            in: messages
        )
    }

    var body: some View {
        List {
            if links.isEmpty {
                ContentUnavailableView(
                    "No Links",
                    systemImage: "link"
                )
            }

            ForEach(links, id: \.absoluteString) { url in
                Link(destination: url) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(
                            url.host ?? "Link"
                        )
                        .font(.body.weight(.semibold))

                        Text(url.absoluteString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .navigationTitle("Links")
        .navigationBarTitleDisplayMode(.inline)
    }
}
