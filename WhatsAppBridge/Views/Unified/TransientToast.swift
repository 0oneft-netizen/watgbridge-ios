import SwiftUI

struct TransientToast: View {
    let text: String

    var body: some View {
        Text(text)
            .font(
                .caption.weight(
                    .semibold
                )
            )
            .foregroundStyle(
                .primary
            )
            .padding(
                .horizontal,
                14
            )
            .padding(
                .vertical,
                9
            )
            .background(
                .regularMaterial,
                in: Capsule()
            )
            .shadow(
                radius: 3,
                y: 1
            )
    }
}
