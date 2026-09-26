import SwiftUI

struct CustomerWorkflowEditor: View {
    let conversation:
        Conversation

    @ObservedObject
    private var store =
        CustomerWorkflowStore.shared

    var body: some View {
        Form {
            Section(
                "Conversation status"
            ) {
                ForEach(
                    CustomerWorkflowStage
                        .allCases
                ) { stage in

                    Button {
                        store.setStage(
                            stage,
                            for:
                                conversation
                        )
                    } label: {
                        HStack {
                            Label(
                                stage.title,
                                systemImage:
                                    stage
                                        .systemImage
                            )

                            Spacer()

                            if store
                                .value(
                                    for:
                                        conversation
                                )
                                .stage
                                ==
                                stage {

                                Image(
                                    systemName:
                                        "checkmark"
                                )
                                .foregroundStyle(
                                    .green
                                )
                            }
                        }
                    }
                    .buttonStyle(
                        .plain
                    )
                }
            }

            Section {
                Toggle(
                    "Priority customer",
                    isOn:
                        Binding(
                            get: {
                                store
                                    .value(
                                        for:
                                            conversation
                                    )
                                    .priority
                            },
                            set: { _ in
                                store
                                    .togglePriority(
                                        conversation
                                    )
                            }
                        )
                )
            }
        }
        .navigationTitle(
            "Workflow"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
