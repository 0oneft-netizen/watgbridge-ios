import SwiftUI

struct ConversationMediaBrowser: View {
    let messages: [Message]

    private let columns = [
        GridItem(.adaptive(minimum: 105), spacing: 2)
    ]

    var body: some View {
        ScrollView {
            if messages.isEmpty {
                ContentUnavailableView(
                    "No Media",
                    systemImage: "photo.on.rectangle"
                )
                .padding(.top, 80)
            } else {
                LazyVGrid(
                    columns: columns,
                    spacing: 2
                ) {
                    ForEach(messages) { message in
                        MediaGridItem(message: message)
                    }
                }
            }
        }
        .navigationTitle("Media")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MediaGridItem: View {
    let message: Message

    @State private var localURL: URL?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    Color.secondary.opacity(0.08)
                )

            if let localURL,
               let data = try? Data(
                    contentsOf: localURL
               ),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(
                    systemName:
                        message.type == "video"
                        ? "play.rectangle.fill"
                        : "photo"
                )
                .font(.title2)
                .foregroundStyle(.secondary)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .task {
            guard
                MessageMediaPolicy.mayPersist(message)
            else {
                return
            }

            localURL =
                await MediaCache.shared.localURL(
                    for: message
                )
        }
    }
}
