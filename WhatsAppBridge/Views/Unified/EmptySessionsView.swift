import SwiftUI

struct EmptySessionsView: View {
    var body: some View {
        ContentUnavailableView {
            Label(
                "No Accounts",
                systemImage:
                    "iphone.slash"
            )
        } description: {
            Text(
                "Connected WhatsApp accounts will appear here."
            )
        }
    }
}
