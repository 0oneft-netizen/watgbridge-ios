import SwiftUI

struct MessageSelectionIndicator: View {
    let selected: Bool

    var body: some View {
        Image(
            systemName:
                selected
                ? "checkmark.circle.fill"
                : "circle"
        )
        .font(.title3)
        .foregroundStyle(
            selected
            ? Color.green
            : Color.secondary
        )
        .contentTransition(
            .symbolEffect(
                .replace
            )
        )
    }
}
