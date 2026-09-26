import SwiftUI

struct QuickReplySuggestions: View {
    let accountID: String
    let text: String
    let select:
        (String) -> Void

    private var replies:
        [SessionQuickReply] {

        SessionQuickReplyMatcher
            .matches(
                accountID:
                    accountID,
                composerText:
                    text
            )
    }

    var body: some View {
        if text.hasPrefix("/"),
           !replies.isEmpty {

            ScrollView(
                .horizontal,
                showsIndicators:
                    false
            ) {
                HStack(spacing: 8) {
                    ForEach(replies) {
                        reply in

                        Button {
                            select(
                                reply.text
                            )
                        } label: {
                            VStack(
                                alignment:
                                    .leading,
                                spacing: 2
                            ) {
                                Text(
                                    "/"
                                    +
                                    reply.shortcut
                                )
                                .font(
                                    .caption.bold()
                                )

                                Text(
                                    reply.text
                                )
                                .font(
                                    .caption2
                                )
                                .lineLimit(1)
                            }
                            .padding(
                                .horizontal,
                                10
                            )
                            .padding(
                                .vertical,
                                7
                            )
                            .background(
                                .regularMaterial,
                                in:
                                    RoundedRectangle(
                                        cornerRadius:
                                            10
                                    )
                            )
                        }
                        .buttonStyle(
                            .plain
                        )
                    }
                }
                .padding(
                    .horizontal,
                    10
                )
            }
        }
    }
}
