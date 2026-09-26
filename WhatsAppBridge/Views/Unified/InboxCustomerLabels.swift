import SwiftUI

struct InboxCustomerLabels: View {
    let conversation: Conversation

    @ObservedObject
    private var store =
        CustomerMetadataStore.shared

    private var labels:
        [String] {
        Array(
            store
                .metadata(
                    for:
                        conversation
                )
                .labels
                .prefix(2)
        )
    }

    var body: some View {
        if !labels.isEmpty {
            HStack(spacing: 4) {
                ForEach(
                    labels,
                    id: \.self
                ) {
                    CustomerLabelChip(
                        text: $0
                    )
                }
            }
        }
    }
}
