import SwiftUI
import AVKit

struct ChatMediaGalleryView: View {
    let messages: [Message]

    @State private var selectedTab = 0

    private var mediaMessages: [Message] {
        messages.filter {
            [
                "image",
                "video",
                "video_note",
                "gif"
            ].contains($0.type)
            &&
            !$0.type.hasPrefix("view_once")
        }
    }

    private var documentMessages: [Message] {
        messages.filter {
            $0.type == "document"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker(
                "Content",
                selection: $selectedTab
            ) {
                Text("Media").tag(0)
                Text("Docs").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                mediaGrid
            } else {
                documents
            }
        }
        .navigationTitle(
            "Media, Links and Docs"
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private var mediaGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(
                        .flexible(),
                        spacing: 2
                    ),
                    GridItem(
                        .flexible(),
                        spacing: 2
                    ),
                    GridItem(
                        .flexible(),
                        spacing: 2
                    )
                ],
                spacing: 2
            ) {
                ForEach(
                    mediaMessages,
                    id: \.id
                ) { message in
                    NavigationLink {
                        MediaDetailScreen(
                            message: message
                        )
                    } label: {
                        MediaGridThumbnail(
                            message: message
                        )
                    }
                }
            }
        }
    }

    private var documents: some View {
        List(
            documentMessages,
            id: \.id
        ) { message in
            HStack(spacing: 12) {
                Image(
                    systemName:
                        "doc.fill"
                )
                .font(.title2)
                .foregroundStyle(
                    ChatDesign.accent
                )

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(
                        message.fileName
                        ?? "Document"
                    )
                    .lineLimit(1)

                    Text(
                        message.mimeType
                        ?? "File"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }
    }
}

private struct MediaGridThumbnail: View {
    let message: Message

    @State private var localURL: URL?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    Color.secondary.opacity(
                        0.12
                    )
                )

            if message.type == "image",
               let localURL,
               let data =
                    try? Data(
                        contentsOf: localURL
                    ),
               let image =
                    UIImage(data: data) {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()

            } else if [
                "video",
                "video_note",
                "gif"
            ].contains(message.type) {

                Image(
                    systemName:
                        "play.circle.fill"
                )
                .font(.largeTitle)
                .foregroundStyle(.white)

            } else {
                ProgressView()
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
        .task {
            guard !message.type
                .hasPrefix("view_once")
            else {
                return
            }

            guard let remote =
                APIClient.shared.mediaURL(
                    for: message.messageID,
                    accountID:
                        message.accountID
                )
            else {
                return
            }

            localURL = try? await
                MediaCache.shared.localURL(
                    remoteURL: remote,
                    messageID:
                        "\(message.accountID)-\(message.messageID)",
                    fileName:
                        message.fileName,
                    mimeType:
                        message.mimeType
                )
        }
    }
}

private struct MediaDetailScreen: View {
    let message: Message

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            MessageMediaView(
                message: message
            )
        }
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
