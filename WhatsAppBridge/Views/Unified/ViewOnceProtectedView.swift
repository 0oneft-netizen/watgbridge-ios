import SwiftUI

struct ViewOnceProtectedView: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(
                systemName:
                    "1.circle"
            )

            Text(
                "View once media"
            )
        }
        .font(
            .subheadline
                .weight(
                    .medium
                )
        )
        .foregroundStyle(
            .secondary
        )
        .padding(
            .vertical,
            8
        )
    }
}
