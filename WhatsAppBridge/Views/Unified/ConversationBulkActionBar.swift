import SwiftUI

struct ConversationBulkActionBar: View {
    let count: Int
    let action:
        (ConversationBulkAction)
        -> Void

    var body: some View {
        HStack {
            Text(
                "\(count) selected"
            )
            .font(
                .subheadline.bold()
            )

            Spacer()

            ForEach(
                actions,
                id: \.self
            ) { item in

                Button {
                    action(item)
                } label: {
                    Image(
                        systemName:
                            item
                                .systemImage
                    )
                }
                .accessibilityLabel(
                    item.title
                )
            }
        }
        .padding(
            .horizontal,
            16
        )
        .frame(height: 48)
        .background(
            .regularMaterial
        )
    }

    private var actions:
        [ConversationBulkAction] {
        [
            .markUnread,
            .archive,
            .priority,
            .done
        ]
    }
}
