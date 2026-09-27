import SwiftUI

struct SharedContentSummary: View {
    let messages: [Message]

    private var mediaCount: Int {
        messages.filter {
            [
                "image",
                "video",
                "gif",
                "video_note",
                "ptv"
            ].contains(
                $0.type.lowercased()
            )
            &&
            !MessageMediaPolicy
                .isViewOnce($0)
        }
        .count
    }

    private var documentCount: Int {
        messages.filter {
            $0.type.lowercased()
                == "document"
            &&
            !MessageMediaPolicy
                .isViewOnce($0)
        }
        .count
    }

    private var linkCount: Int {
        MessageContentDetector
            .links(
                in:
                    messages.filter {
                        !MessageMediaPolicy
                            .isViewOnce($0)
                    }
            )
            .count
    }

    var body: some View {
        HStack(spacing: 0) {
            item(
                icon:
                    "photo.on.rectangle",
                title: "Media",
                value: mediaCount
            )

            Divider()
                .frame(height: 35)

            item(
                icon: "doc.fill",
                title: "Docs",
                value: documentCount
            )

            Divider()
                .frame(height: 35)

            item(
                icon: "link",
                title: "Links",
                value: linkCount
            )
        }
        .frame(
            maxWidth: .infinity
        )
    }

    private func item(
        icon: String,
        title: String,
        value: Int
    ) -> some View {
        VStack(spacing: 4) {
            Image(
                systemName: icon
            )
            .foregroundStyle(
                AppVisualDesign.accent
            )

            Text("\(value)")
                .font(
                    .subheadline.weight(
                        .semibold
                    )
                )

            Text(title)
                .font(.caption2)
                .foregroundStyle(
                    .secondary
                )
        }
        .frame(
            maxWidth: .infinity
        )
    }
}
