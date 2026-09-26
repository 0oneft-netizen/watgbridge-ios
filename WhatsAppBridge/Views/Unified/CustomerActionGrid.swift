import SwiftUI
import UIKit

struct CustomerActionGrid: View {
    let conversation:
        Conversation

    var body: some View {
        HStack(spacing: 10) {
            action(
                title:
                    "Copy",
                icon:
                    "doc.on.doc"
            ) {
                UIPasteboard
                    .general
                    .string =
                        ChatIdentity
                            .customerPhone(
                                from:
                                    conversation.jid
                            )
            }

            action(
                title:
                    "Search",
                icon:
                    "magnifyingglass"
            ) {}

            action(
                title:
                    "Media",
                icon:
                    "photo.on.rectangle"
            ) {}

            action(
                title:
                    "More",
                icon:
                    "ellipsis"
            ) {}
        }
    }

    private func action(
        title: String,
        icon: String,
        perform:
            @escaping () -> Void
    ) -> some View {

        Button(
            action:
                perform
        ) {
            VStack(spacing: 6) {
                Image(
                    systemName:
                        icon
                )
                .font(.title3)

                Text(title)
                    .font(.caption)
            }
            .frame(
                maxWidth:
                    .infinity
            )
            .padding(
                .vertical,
                10
            )
            .background(
                Color.secondary
                    .opacity(0.08),
                in:
                    RoundedRectangle(
                        cornerRadius:
                            12
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
