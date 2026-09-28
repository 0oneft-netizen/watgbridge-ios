import SwiftUI
import UIKit

struct CustomerSessionHeader: View {
    let customerName: String
    let customerPhone: String
    let sessionName: String

    var body: some View {
        VStack(spacing: 2) {
            Text(customerName)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 5) {
                Image(systemName: "phone.fill")
                    .font(.caption2)

                Text(customerPhone)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let value =
                                customerPhone
                                    .trimmingCharacters(
                                        in: .whitespacesAndNewlines
                                    )

                            guard !value.isEmpty else {
                                return
                            }

                            UIPasteboard.general.string =
                                value

                            let generator =
                                UINotificationFeedbackGenerator()
                            generator.notificationOccurred(
                                .success
                            )
                        }

                Text("•")

                Image(systemName: "iphone")
                    .font(.caption2)

                Text(sessionName)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}
