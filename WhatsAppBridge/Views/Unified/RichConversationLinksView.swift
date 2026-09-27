import SwiftUI

struct RichConversationLinksView: View {
    let messages: [Message]

    private var links: [URL] {
        MessageContentDetector.links(
            in: messages.filter {
                !MessageMediaPolicy
                    .isViewOnce($0)
            }
        )
    }

    var body: some View {
        List {
            if links.isEmpty {
                ContentUnavailableView(
                    "No Links",
                    systemImage: "link",
                    description:
                        Text(
                            "Links shared in this conversation appear here."
                        )
                )
            } else {
                ForEach(
                    links,
                    id: \.absoluteString
                ) { url in
                    Link(
                        destination: url
                    ) {
                        linkRow(url)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Links")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .tint(
            AppVisualDesign.accent
        )
    }

    private func linkRow(
        _ url: URL
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
                .fill(
                    AppVisualDesign
                        .accent
                        .opacity(0.10)
                )

                Image(
                    systemName:
                        "link"
                )
                .font(
                    .system(
                        size: 18,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    AppVisualDesign.accent
                )
            }
            .frame(
                width: 46,
                height: 46
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(
                    url.host
                    ?? "Link"
                )
                .font(
                    .body.weight(
                        .semibold
                    )
                )
                .foregroundStyle(
                    .primary
                )
                .lineLimit(1)

                Text(
                    url.absoluteString
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
                .lineLimit(2)
            }

            Spacer(minLength: 4)

            Image(
                systemName:
                    "arrow.up.right"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(
                AppVisualDesign.accent
            )
        }
        .padding(.vertical, 5)
    }
}
