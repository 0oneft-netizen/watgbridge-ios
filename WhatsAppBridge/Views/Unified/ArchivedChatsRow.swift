import SwiftUI

struct ArchivedChatsRow: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        if count > 0 {
            Button(action: action) {
                HStack(spacing: 14) {
                    Image(
                        systemName:
                            "archivebox.fill"
                    )
                    .frame(width: 28)

                    Text(
                        "Archived"
                    )
                    .font(
                        .body.weight(
                            .semibold
                        )
                    )

                    Spacer()

                    Text("\(count)")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
                .padding(
                    .horizontal,
                    16
                )
                .frame(height: 48)
            }
            .buttonStyle(.plain)
        }
    }
}
