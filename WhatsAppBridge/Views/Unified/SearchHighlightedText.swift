import SwiftUI

struct SearchHighlightedText: View {
    let text: String
    let query: String

    var body: some View {
        Text(attributed)
    }

    private var attributed:
        AttributedString {

        var value =
            AttributedString(text)

        let trimmed =
            query.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard
            !trimmed.isEmpty
        else {
            return value
        }

        var searchStart =
            value.startIndex

        while searchStart <
                value.endIndex,
              let range =
                value[
                    searchStart...
                ].range(
                    of: trimmed,
                    options:
                        .caseInsensitive
                ) {

            value[range]
                .backgroundColor =
                    .yellow.opacity(
                        0.35
                    )

            searchStart =
                range.upperBound
        }

        return value
    }
}
