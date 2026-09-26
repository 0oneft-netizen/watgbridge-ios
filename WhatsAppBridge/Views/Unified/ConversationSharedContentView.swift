import SwiftUI

struct ConversationSharedContentView: View {
    let messages: [Message]

    @State
    private var selection:
        ConversationMediaFilter = .media

    private var filtered: [Message] {
        messages.filter {
            selection.includes($0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            MediaFilterPicker(
                selection: $selection
            )
            .padding()

            if filtered.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: emptyIcon
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            } else {
                List(filtered) { message in
                    row(message)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Shared Content")
        .navigationBarTitleDisplayMode(
            .inline
        )
    }

    @ViewBuilder
    private func row(
        _ message: Message
    ) -> some View {
        HStack(spacing: 11) {
            Image(
                systemName:
                    MessagePresentation
                        .systemImage(
                            for: message
                        )
                    ?? "message"
            )
            .frame(width: 28)
            .foregroundStyle(
                ChatDesign.accent
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(
                    MessagePresentation
                        .fallbackText(
                            for: message
                        )
                )
                .lineLimit(2)

                Text(
                    MessageDatePresentation
                        .dayLabel(
                            message.createdAt
                        )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyTitle: String {
        switch selection {
        case .media:
            return "No Media"
        case .documents:
            return "No Documents"
        case .links:
            return "No Links"
        }
    }

    private var emptyIcon: String {
        switch selection {
        case .media:
            return "photo.on.rectangle"
        case .documents:
            return "doc"
        case .links:
            return "link"
        }
    }
}
