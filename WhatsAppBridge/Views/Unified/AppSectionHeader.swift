import SwiftUI

struct AppSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(
                    .system(
                        size: 20,
                        weight: .bold
                    )
                )

            Spacer()

            if let actionTitle,
               let action {

                Button(
                    actionTitle,
                    action: action
                )
                .font(
                    .subheadline.weight(
                        .semibold
                    )
                )
                .foregroundStyle(
                    AppVisualDesign.accent
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
    }
}
