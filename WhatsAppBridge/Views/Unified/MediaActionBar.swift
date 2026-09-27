import SwiftUI

struct MediaActionBar: View {
    let message: Message

    let save: () -> Void
    let share: () -> Void
    let forward: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            if MediaOperationPolicy
                .maySave(message) {

                actionButton(
                    title: "Save",
                    icon:
                        "square.and.arrow.down",
                    action: save
                )
            }

            if MediaOperationPolicy
                .mayShare(message) {

                actionButton(
                    title: "Share",
                    icon:
                        "square.and.arrow.up",
                    action: share
                )
            }

            if MediaOperationPolicy
                .mayForward(message) {

                actionButton(
                    title: "Forward",
                    icon:
                        "arrowshape.turn.up.right",
                    action: forward
                )
            }
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(.vertical, 7)
        .background(
            .ultraThinMaterial
        )
    }

    private func actionButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            action: action
        ) {
            VStack(spacing: 4) {
                Image(
                    systemName: icon
                )
                .font(
                    .system(
                        size: 17,
                        weight: .medium
                    )
                )

                Text(title)
                    .font(
                        .system(
                            size: 11,
                            weight: .medium
                        )
                    )
            }
            .foregroundStyle(
                AppVisualDesign.accent
            )
            .frame(
                maxWidth: .infinity
            )
        }
        .buttonStyle(.plain)
    }
}
