import SwiftUI

struct CustomerSummaryCard: View {
    let conversation: Conversation

    @ObservedObject
    private var metadata =
        CustomerMetadataStore.shared

    private var item:
        CustomerMetadata {
        metadata.metadata(
            for: conversation
        )
    }

    var body: some View {
        if !item.note.isEmpty ||
            !item.labels.isEmpty {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                if !item.labels.isEmpty {
                    ScrollView(
                        .horizontal,
                        showsIndicators:
                            false
                    ) {
                        HStack(
                            spacing: 6
                        ) {
                            ForEach(
                                item.labels,
                                id: \.self
                            ) {
                                label in

                                Label(
                                    label,
                                    systemImage:
                                        "tag.fill"
                                )
                                .font(
                                    .caption
                                )
                                .padding(
                                    .horizontal,
                                    9
                                )
                                .padding(
                                    .vertical,
                                    5
                                )
                                .background(
                                    Color.green
                                        .opacity(
                                            0.10
                                        ),
                                    in:
                                        Capsule()
                                )
                            }
                        }
                    }
                }

                if !item.note.isEmpty {
                    Text(item.note)
                        .font(
                            .subheadline
                        )
                        .foregroundStyle(
                            .secondary
                        )
                        .lineLimit(4)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
