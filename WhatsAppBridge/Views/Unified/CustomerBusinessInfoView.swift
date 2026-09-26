import SwiftUI

struct CustomerBusinessInfoView: View {
    let conversation: Conversation

    @ObservedObject
    private var store = CustomerMetadataStore.shared

    @State private var note = ""
    @State private var newLabel = ""

    private var metadata: CustomerMetadata {
        store.metadata(for: conversation)
    }

    var body: some View {
        Form {
            Section("Private note") {
                TextEditor(text: $note)
                    .frame(minHeight: 110)

                Button("Save note") {
                    store.setNote(note, for: conversation)
                }
                .disabled(
                    note.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) == metadata.note
                )
            }

            Section("Labels") {
                if metadata.labels.isEmpty {
                    Text("No labels")
                        .foregroundStyle(.secondary)
                }

                ForEach(metadata.labels, id: \.self) { label in
                    HStack {
                        Label(label, systemImage: "tag")

                        Spacer()

                        Button(role: .destructive) {
                            store.removeLabel(label, from: conversation)
                        } label: {
                            Image(systemName: "xmark.circle")
                        }
                    }
                }

                HStack {
                    TextField("New label", text: $newLabel)

                    Button("Add") {
                        store.addLabel(newLabel, to: conversation)
                        newLabel = ""
                    }
                    .disabled(
                        newLabel.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
        }
        .navigationTitle("Customer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            note = metadata.note
        }
    }
}
