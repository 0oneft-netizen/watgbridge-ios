import SwiftUI

struct CustomerFollowUpView: View {
    let conversation:
        Conversation

    @Environment(\.dismiss)
    private var dismiss

    @ObservedObject
    private var store =
        CustomerFollowUpStore.shared

    @State
    private var dueAt =
        Date()
            .addingTimeInterval(
                3600
            )

    @State
    private var note = ""

    var body: some View {
        Form {
            Section(
                "Follow Up"
            ) {
                DatePicker(
                    "Remind",
                    selection:
                        $dueAt,
                    in:
                        Date()...,
                    displayedComponents:
                        [
                            .date,
                            .hourAndMinute
                        ]
                )

                TextField(
                    "Note",
                    text: $note,
                    axis: .vertical
                )
                .lineLimit(
                    2...5
                )
            }

            Section {
                Button(
                    "Save Follow Up"
                ) {
                    store.set(
                        conversation:
                            conversation,
                        dueAt:
                            dueAt,
                        note:
                            note
                    )

                    CustomerWorkflowStore
                        .shared
                        .setStage(
                            .followUp,
                            for:
                                conversation
                        )

                    dismiss()
                }
            }

            if let existing =
                store.value(
                    for:
                        conversation
                ) {

                Section(
                    "Current"
                ) {
                    LabeledContent(
                        "Due",
                        value:
                            existing
                                .dueAt
                                .formatted(
                                    date:
                                        .abbreviated,
                                    time:
                                        .shortened
                                )
                    )

                    if !existing
                        .note
                        .isEmpty {

                        Text(
                            existing.note
                        )
                    }

                    if !existing.completed {
                        Button(
                            "Mark Complete"
                        ) {
                            store.complete(
                                conversation
                            )

                            dismiss()
                        }
                    }

                    Button(
                        "Remove Follow Up",
                        role:
                            .destructive
                    ) {
                        store.remove(
                            conversation
                        )

                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(
            "Follow Up"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .onAppear {
            if let item =
                store.value(
                    for:
                        conversation
                ) {

                dueAt =
                    max(
                        Date(),
                        item.dueAt
                    )

                note =
                    item.note
            }
        }
    }
}
