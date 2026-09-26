import SwiftUI

struct ActiveChatScrollControls: View {
    let remaining:
        Int

    let unseen:
        Int

    let loadEarlier:
        () -> Void

    let jumpToLatest:
        () -> Void

    var body: some View {
        VStack(
            alignment:
                .trailing,
            spacing: 10
        ) {
            if remaining > 0 {
                LoadEarlierMessagesButton(
                    remaining:
                        remaining,
                    action:
                        loadEarlier
                )
            }

            if unseen > 0 {
                SmartJumpToLatestButton(
                    unseen:
                        unseen,
                    action:
                        jumpToLatest
                )
            }
        }
    }
}
