import SwiftUI

struct ConversationStateIcons: View {
    let pinned: Bool
    let muted: Bool

    var body: some View {
        HStack(spacing: 5) {
            if pinned {
                Image(
                    systemName: "pin.fill"
                )
            }

            if muted {
                Image(
                    systemName:
                        "speaker.slash.fill"
                )
            }
        }
        .font(.system(size: 10))
        .foregroundStyle(.secondary)
        .accessibilityHidden(
            !pinned && !muted
        )
    }
}
