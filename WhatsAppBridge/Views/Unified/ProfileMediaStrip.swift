import SwiftUI
import UIKit

struct ProfileMediaStrip: View {
    let messages: [Message]

    private var media: [Message] {
        Array(
            messages
                .filter {
                    MessageMediaPolicy
                        .isRenderableMedia(
                            $0
                        )
                    &&
                    !MessageMediaPolicy
                        .isViewOnce($0)
                }
                .suffix(12)
                .reversed()
        )
    }

    var body: some View {
        if !media.isEmpty {
            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                LazyHStack(spacing: 3) {
                    ForEach(media) {
                        message in

                        ProfileMediaThumbnail(
                            message:
                                message
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
            .frame(height: 84)
        }
    }
}

private struct ProfileMediaThumbnail:
    View {

    let message: Message

    @State
    private var localURL: URL?

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 7
            )
            .fill(
                Color.secondary
                    .opacity(0.10)
            )

            if let localURL,
               let data =
                try? Data(
                    contentsOf:
                        localURL
                ),
               let image =
                UIImage(data: data) {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()

            } else {
                Image(
                    systemName:
                        message.type ==
                            "video"
                        ? "play.fill"
                        : "photo"
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .frame(
            width: 82,
            height: 82
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 7
            )
        )
        .task {
            guard
                MessageMediaPolicy
                    .mayPersist(
                        message
                    )
            else {
                return
            }

            localURL =
                await MediaCache
                    .shared
                    .localURL(
                        for:
                            message
                    )
        }
    }
}
