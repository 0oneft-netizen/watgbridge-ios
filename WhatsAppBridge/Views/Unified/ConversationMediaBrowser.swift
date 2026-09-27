import SwiftUI
import UIKit

struct ConversationMediaBrowser: View {
    let messages: [Message]

    private let columns = [
        GridItem(
            .adaptive(minimum: 105),
            spacing: 2
        )
    ]

    private var safeMessages: [Message] {
        messages.filter {
            MessageMediaPolicy
                .isRenderableMedia($0)
            &&
            !MessageMediaPolicy
                .isViewOnce($0)
        }
    }

    var body: some View {
        ScrollView {
            if safeMessages.isEmpty {
                ContentUnavailableView(
                    "No Media",
                    systemImage:
                        "photo.on.rectangle",
                    description:
                        Text(
                            "Photos and videos shared in this conversation appear here."
                        )
                )
                .padding(.top, 80)
            } else {
                LazyVGrid(
                    columns: columns,
                    spacing: 2
                ) {
                    ForEach(safeMessages) {
                        message in

                        MediaGridItem(
                            message: message
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .background(
            Color(
                uiColor:
                    .systemBackground
            )
        )
        .navigationTitle("Media")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .tint(
            AppVisualDesign.accent
        )
    }
}

private struct MediaGridItem: View {
    let message: Message

    @State
    private var localURL: URL?

    private var isVideo: Bool {
        [
            "video",
            "video_note",
            "ptv"
        ].contains(
            message.type.lowercased()
        )
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    Color.secondary
                        .opacity(0.08)
                )

            if let localURL,
               let data =
                try? Data(
                    contentsOf: localURL
                ),
               let image =
                UIImage(data: data) {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()

            } else {
                VStack(spacing: 6) {
                    Image(
                        systemName:
                            isVideo
                            ? "play.fill"
                            : "photo"
                    )
                    .font(.title2)

                    if isVideo {
                        Text("Video")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(
                    .secondary
                )
            }

            if isVideo {
                VStack {
                    Spacer()

                    HStack {
                        Image(
                            systemName:
                                "play.fill"
                        )
                        .font(.caption)

                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(
                        LinearGradient(
                            colors: [
                                .clear,
                                .black.opacity(0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
        .aspectRatio(
            1,
            contentMode: .fit
        )
        .clipped()
        .contentShape(Rectangle())
        .task {
            await loadMedia()
        }
    }

    @MainActor
    private func loadMedia() async {
        guard
            MessageMediaPolicy
                .mayPersist(message)
        else {
            return
        }

        guard
            !MessageMediaPolicy
                .isViewOnce(message)
        else {
            return
        }

        guard
            let remoteURL =
                APIClient.shared.mediaURL(
                    for:
                        message.messageID,
                    accountID:
                        message.accountID
                )
        else {
            return
        }

        localURL =
            try? await MediaCache.shared
                .localURL(
                    remoteURL:
                        remoteURL,
                    messageID:
                        "\(message.accountID ?? "default")_\(message.messageID)",
                    fileName:
                        message.fileName,
                    mimeType:
                        message.mimeType
                )
    }
}
