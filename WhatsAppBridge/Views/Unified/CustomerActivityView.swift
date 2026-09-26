import SwiftUI

struct CustomerActivityView: View {
    let messages:
        [Message]

    private var snapshot:
        ConversationActivitySnapshot {
        ConversationActivity
            .snapshot(
                messages:
                    messages
            )
    }

    var body: some View {
        List {
            Section(
                "Messages"
            ) {
                LabeledContent(
                    "Received",
                    value:
                        "\(snapshot.incoming)"
                )

                LabeledContent(
                    "Sent",
                    value:
                        "\(snapshot.outgoing)"
                )

                LabeledContent(
                    "Media",
                    value:
                        "\(snapshot.media)"
                )
            }

            Section(
                "Activity"
            ) {
                if let first =
                    snapshot.firstMessage {

                    LabeledContent(
                        "First message",
                        value:
                            first.formatted(
                                date:
                                    .abbreviated,
                                time:
                                    .shortened
                            )
                    )
                }

                if let last =
                    snapshot.lastMessage {

                    LabeledContent(
                        "Last message",
                        value:
                            last.formatted(
                                date:
                                    .abbreviated,
                                time:
                                    .shortened
                            )
                    )
                }
            }
        }
        .navigationTitle(
            "Activity"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
