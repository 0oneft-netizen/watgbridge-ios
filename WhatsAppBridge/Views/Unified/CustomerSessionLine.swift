import SwiftUI

struct CustomerSessionLine: View {
    let customerPhone: String
    let accountID: String?

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    private var sessionName: String {
        sessions.name(
            for: accountID
        )
    }

    var body: some View {
        HStack(spacing: 5) {
            Text(customerPhone)

            Text("•")
                .foregroundStyle(
                    .tertiary
                )

            Text(sessionName)
                .fontWeight(.medium)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .task {
            if sessions.sessions.isEmpty {
                await sessions.refresh()
            }
        }
    }
}
