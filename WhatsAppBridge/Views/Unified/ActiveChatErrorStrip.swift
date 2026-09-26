import SwiftUI

struct ActiveChatErrorStrip: View {
    let error:
        String?

    let retry:
        (() -> Void)?

    var body: some View {
        if let error,
           !error.isEmpty {

            HStack(spacing: 8) {
                Image(
                    systemName:
                        "exclamationmark.triangle"
                )

                Text(
                    error
                )
                .font(.caption)
                .lineLimit(2)

                Spacer()

                if let retry {
                    Button(
                        "Retry",
                        action:
                            retry
                    )
                    .font(
                        .caption.bold()
                    )
                }
            }
            .padding(
                .horizontal,
                12
            )
            .padding(
                .vertical,
                8
            )
            .background(
                Color.orange
                    .opacity(0.13)
            )
        }
    }
}
