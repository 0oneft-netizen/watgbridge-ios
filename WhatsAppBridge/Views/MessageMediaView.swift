import SwiftUI
import AVKit

struct MessageMediaView: View {
    let message: Message

    var body: some View {
        if let url =
            APIClient.shared.mediaURL(
                for: message.messageID
            ) {

            switch message.type {

            case "image":
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: 250,
                                height: 250
                            )
                            .clipped()
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 10
                                )
                            )

                    case .failure:
                        placeholder(
                            "Photo",
                            icon: "photo"
                        )

                    default:
                        ProgressView()
                            .frame(
                                width: 250,
                                height: 180
                            )
                    }
                }

            case "video":
                VideoPlayer(
                    player:
                        AVPlayer(url: url)
                )
                .frame(
                    width: 250,
                    height: 190
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                )

            case "voice":
                AudioMessageView(
                    url: url,
                    isVoice: true
                )

            case "audio":
                AudioMessageView(
                    url: url,
                    isVoice: false
                )

            case "document":
                Link(
                    destination: url
                ) {
                    HStack(spacing: 10) {
                        Image(
                            systemName:
                                "doc.fill"
                        )
                        .font(.title2)

                        VStack(
                            alignment: .leading
                        ) {
                            Text(
                                message.fileName?
                                    .isEmpty == false
                                ? message.fileName!
                                : "Document"
                            )
                            .font(
                                .subheadline
                                    .weight(
                                        .semibold
                                    )
                            )
                            .lineLimit(2)

                            if let mime =
                                message.mimeType,
                               !mime.isEmpty {

                                Text(mime)
                                    .font(
                                        .caption2
                                    )
                                    .foregroundStyle(
                                        .secondary
                                    )
                            }
                        }

                        Spacer()

                        Image(
                            systemName:
                                "arrow.down.circle"
                        )
                    }
                    .padding(10)
                    .background(
                        Color.secondary
                            .opacity(0.08)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 10
                        )
                    )
                }

            default:
                EmptyView()
            }

        } else if message.type != "text" {
            placeholder(
                message.type.capitalized,
                icon: "paperclip"
            )
        }
    }

    private func placeholder(
        _ title: String,
        icon: String
    ) -> some View {

        Label(
            title,
            systemImage: icon
        )
        .frame(
            minWidth: 160,
            minHeight: 44
        )
    }
}
