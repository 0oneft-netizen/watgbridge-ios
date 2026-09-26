import SwiftUI

struct MessageBodyRouter: View {
    let message:
        Message

    var body: some View {
        if MessageMediaPolicy
            .isViewOnce(
                message
            ) {

            ViewOnceProtectedView()

        } else if RenderableMessagePolicy
            .hasMedia(
                message
            ) {

            MessageMediaView(
                message:
                    message
            )

        } else if RenderableMessagePolicy
            .hasText(
                message
            ) {

            Text(
                message.text
            )
            .font(
                .system(
                    size: 16
                )
            )
            .textSelection(
                .enabled
            )

        } else {
            UnsupportedMessageView(
                message:
                    message
            )
        }
    }
}
