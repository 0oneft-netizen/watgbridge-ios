import SwiftUI

struct MessageBulkActionBar: View {
    let count: Int

    let onCancel: () -> Void
    let onForward: () -> Void
    let onStar: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 22) {
            Button(
                action: onCancel
            ) {
                Image(
                    systemName: "xmark"
                )
            }

            Text("\(count)")
                .font(
                    .headline
                )

            Spacer()

            Button(
                action: onStar
            ) {
                Image(
                    systemName: "star"
                )
            }

            Button(
                action: onForward
            ) {
                Image(
                    systemName: "arrowshape.turn.up.right"
                )
            }

            Button(
                role: .destructive,
                action: onDelete
            ) {
                Image(
                    systemName: "trash"
                )
            }
        }
        .font(.title3)
        .padding(.horizontal, 18)
        .frame(height: 50)
        .background(
            .regularMaterial
        )
    }
}
