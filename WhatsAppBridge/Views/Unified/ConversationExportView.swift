import SwiftUI

struct ConversationExportView: View {
    let messages:
        [Message]

    private var exportText:
        String {
        ConversationExportPolicy
            .text(
                messages:
                    messages
            )
    }

    var body: some View {
        List {
            Section {
                Text(
                    exportText
                )
                .font(
                    .system(
                        .caption,
                        design:
                            .monospaced
                    )
                )
                .textSelection(
                    .enabled
                )
            }

            Section {
                ShareLink(
                    item:
                        exportText
                ) {
                    Label(
                        "Share Export",
                        systemImage:
                            "square.and.arrow.up"
                    )
                }
            }

            Section {
                Text(
                    "View Once content is excluded."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .navigationTitle(
            "Export Chat"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
