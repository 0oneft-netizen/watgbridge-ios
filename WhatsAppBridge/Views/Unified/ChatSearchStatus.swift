import SwiftUI

struct ChatSearchStatus: View {
    let query:
        String

    let resultCount:
        Int

    var body: some View {
        if !query
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty {

            Text(
                resultCount == 1
                ? "1 result"
                : "\(resultCount) results"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
            .padding(
                .horizontal,
                12
            )
        }
    }
}
