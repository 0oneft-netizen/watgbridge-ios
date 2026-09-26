import SwiftUI

struct SearchHighlightedText: View {
    let text: String
    let query: String

    var body: some View {
        if query.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty {
            Text(text)
        } else {
            highlighted
        }
    }

    private var highlighted: Text {
        let needle = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard
            !needle.isEmpty,
            let range = text.range(
                of: needle,
                options: [.caseInsensitive, .diacriticInsensitive]
            )
        else {
            return Text(text)
        }

        let before = String(text[..<range.lowerBound])
        let match = String(text[range])
        let after = String(text[range.upperBound...])

        return Text(before)
            + Text(match).bold()
            + Text(after)
    }
}
