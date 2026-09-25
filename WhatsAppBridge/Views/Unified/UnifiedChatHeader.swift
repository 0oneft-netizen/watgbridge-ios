import SwiftUI

struct UnifiedChatHeader: View {
    let title: String
    let subtitle: String
    let unread: Int

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        ChatDesign.accent.opacity(0.15)
                    )

                Image(
                    systemName:
                        "person.2.fill"
                )
                .foregroundStyle(
                    ChatDesign.accent
                )
            }
            .frame(width: 38, height: 38)

            VStack(
                alignment: .leading,
                spacing: 1
            ) {
                Text(title)
                    .font(
                        .headline.weight(
                            .semibold
                        )
                    )
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            UnreadBadge(count: unread)

            Menu {
                Button {
                } label: {
                    Label(
                        "Search",
                        systemImage:
                            "magnifyingglass"
                    )
                }

                Button {
                } label: {
                    Label(
                        "Media, Links and Docs",
                        systemImage:
                            "photo.on.rectangle"
                    )
                }

                Button {
                } label: {
                    Label(
                        "Select Messages",
                        systemImage:
                            "checkmark.circle"
                    )
                }
            } label: {
                Image(
                    systemName:
                        "ellipsis.circle"
                )
                .font(.title3)
            }
        }
        .padding(.vertical, 3)
    }
}
