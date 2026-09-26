import SwiftUI

struct ConversationQuickActionsView: View {
    let onSelect:
        (ConversationQuickAction) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(
                ConversationQuickAction.allCases
            ) { action in
                Button {
                    AppHaptics.selection()
                    onSelect(action)
                } label: {
                    VStack(spacing: 6) {
                        Image(
                            systemName:
                                action.systemImage
                        )
                        .font(.system(size: 17))
                        .foregroundStyle(
                            ChatDesign.accent
                        )

                        Text(action.title)
                            .font(.caption2)
                            .foregroundStyle(
                                .primary
                            )
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 58
                    )
                    .background(
                        ChatDesign.subtleFill,
                        in: RoundedRectangle(
                            cornerRadius: 13,
                            style: .continuous
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
