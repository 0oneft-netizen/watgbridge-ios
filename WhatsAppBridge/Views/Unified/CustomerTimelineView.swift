import SwiftUI

struct CustomerTimelineView: View {
    let conversation:
        Conversation

    let messages:
        [Message]

    @ObservedObject
    private var metadata =
        CustomerMetadataStore.shared

    @ObservedObject
    private var workflow =
        CustomerWorkflowStore.shared

    @ObservedObject
    private var followUps =
        CustomerFollowUpStore.shared

    var body: some View {
        List {
            Section(
                "Customer"
            ) {
                LabeledContent(
                    "Status",
                    value:
                        workflow
                            .value(
                                for:
                                    conversation
                            )
                            .stage
                            .title
                )

                let item =
                    metadata
                        .metadata(
                            for:
                                conversation
                        )

                if !item.labels.isEmpty {
                    VStack(
                        alignment:
                            .leading,
                        spacing: 8
                    ) {
                        Text(
                            "Labels"
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        ScrollView(
                            .horizontal,
                            showsIndicators:
                                false
                        ) {
                            HStack {
                                ForEach(
                                    item.labels,
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

                if !item.note.isEmpty {
                    Text(item.note)
                }
            }

            if let follow =
                followUps.value(
                    for:
                        conversation
                ) {

                Section(
                    "Follow Up"
                ) {
                    Label(
                        follow.dueAt
                            .formatted(
                                date:
                                    .abbreviated,
                                time:
                                    .shortened
                            ),
                        systemImage:
                            follow.completed
                            ? "checkmark.circle"
                            : "bell"
                    )

                    if !follow.note.isEmpty {
                        Text(
                            follow.note
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
            }

            Section(
                "Recent Messages"
            ) {
                ForEach(
                    messages
                        .suffix(30)
                        .reversed()
                ) {
                    message in

                    VStack(
                        alignment:
                            .leading,
                        spacing: 4
                    ) {
                        HStack {
                            Text(
                                message.fromMe
                                ? "You"
                                : "Customer"
                            )
                            .font(
                                .caption.bold()
                            )

                            Spacer()

                            Text(
                                MessageTimestampFormatter
                                    .string(
                                        message
                                            .createdAt
                                    )
                            )
                            .font(
                                .caption2
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }

                        Text(
                            MessageTypePresentation
                                .label(
                                    for:
                                        message
                                )
                        )
                        .lineLimit(3)
                    }
                    .padding(
                        .vertical,
                        3
                    )
                }
            }
        }
        .navigationTitle(
            "Timeline"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
