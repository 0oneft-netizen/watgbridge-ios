import SwiftUI

struct ComposerCharacterCounter: View {
    let text: String

    private var remaining:
        Int {
        ComposerTextPolicy
            .maximumLength
        -
        text.count
    }

    var body: some View {
        if remaining < 500 {
            Text(
                "\(max(0, remaining))"
            )
            .font(
                .caption2
                    .monospacedDigit()
            )
            .foregroundStyle(
                remaining < 100
                ? Color.red
                : Color.secondary
            )
        }
    }
}
