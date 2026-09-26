import SwiftUI

struct ActiveComposerAccessories: View {
    let accountID:
        String

    let text:
        String

    let selectQuickReply:
        (String) -> Void

    let sendState:
        ComposerSendState

    var body: some View {
        VStack(spacing: 4) {
            QuickReplySuggestions(
                accountID:
                    accountID,
                text:
                    text,
                select:
                    selectQuickReply
            )

            HStack {
                Spacer()

                ComposerStatusView(
                    state:
                        sendState
                )
                .padding(
                    .trailing,
                    12
                )
            }
        }
    }
}
