import SwiftUI

struct RenameSessionView: View {
    let accountID: String
    let phone: String

    @State
    private var name: String

    @State
    private var isSaving = false

    @State
    private var error: String?

    @Environment(\.dismiss)
    private var dismiss

    init(
        accountID: String,
        currentName: String,
        phone: String
    ) {
        self.accountID = accountID
        self.phone = phone

        _name = State(
            initialValue: currentName
        )
    }

    var body: some View {
        Form {
            Section("Session") {
                TextField(
                    "Session name",
                    text: $name
                )

                if !phone.isEmpty {
                    LabeledContent(
                        "WhatsApp number",
                        value: phone
                    )
                }
            }

            Section {
                Text(
                    "This name identifies which WhatsApp session received the customer's message."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            if let error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Session Name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(
                placement: .confirmationAction
            ) {
                Button("Save") {
                    save()
                }
                .disabled(
                    isSaving ||
                    name.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
            }
        }
    }

    private func save() {
        let value = name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !value.isEmpty else {
            return
        }

        isSaving = true
        error = nil

        Task {
            do {
                try await APIClient.shared
                    .renameAccount(
                        accountID: accountID,
                        displayName: value
                    )

                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error =
                        error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}
