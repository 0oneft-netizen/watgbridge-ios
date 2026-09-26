import SwiftUI

struct ChatErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(
                "Couldn't Load Messages",
                systemImage:
                    "wifi.exclamationmark"
            )
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                AppHaptics.light()
                retry()
            }
            .buttonStyle(.borderedProminent)
            .tint(ChatDesign.accent)
        }
    }
}
