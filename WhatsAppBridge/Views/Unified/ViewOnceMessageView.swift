import SwiftUI

struct ViewOnceMessageView: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(
                systemName:
                    "viewfinder.circle"
            )
            .font(.title3)

            VStack(
                alignment: .leading,
                spacing: 1
            ) {
                Text("View once")
                    .font(
                        .subheadline.weight(
                            .medium
                        )
                    )

                Text(
                    "This media isn't saved or shared."
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(
            children: .combine
        )
    }
}
