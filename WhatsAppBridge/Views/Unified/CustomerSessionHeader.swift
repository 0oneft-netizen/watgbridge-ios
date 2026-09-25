import SwiftUI

struct CustomerSessionHeader: View {
    let customerName: String
    let customerPhone: String

    let sessionName: String
    let sessionPhone: String

    var body: some View {
        VStack(spacing: 2) {
            Text(customerName)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 5) {
                Text(customerPhone)

                Image(systemName: "arrow.right")
                    .font(.caption2)

                Text(sessionName)

                if !sessionPhone.isEmpty {
                    Text("•")
                    Text(sessionPhone)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .accessibilityElement(
            children: .combine
        )
    }
}
