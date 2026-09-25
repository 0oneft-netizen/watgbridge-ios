import SwiftUI

struct WhatsAppConnectionSetupView: View {
    @Environment(\.dismiss)
    private var dismiss

    let type: WhatsAppConnectionType

    @State private var accountID:
        String?

    @State private var loading = true

    @State private var errorText:
        String?

    var body: some View {
        NavigationStack {
            Group {
                if let accountID {
                    WhatsAppPairingView(
                        accountID: accountID,
                        type: type
                    )
                } else {
                    VStack(spacing: 22) {
                        Spacer()

                        Image(
                            systemName:
                                type == .business
                                ? "briefcase.fill"
                                : "message.fill"
                        )
                        .font(
                            .system(size: 62)
                        )
                        .foregroundStyle(
                            Color.accentColor
                        )

                        Text(
                            type.title
                        )
                        .font(.title.bold())

                        if loading {
                            ProgressView(
                                "Creating connection…"
                            )
                        }

                        if let errorText {
                            Text(errorText)
                                .multilineTextAlignment(
                                    .center
                                )
                                .foregroundStyle(
                                    .red
                                )

                            Button(
                                "Try Again"
                            ) {
                                Task {
                                    await create()
                                }
                            }
                            .buttonStyle(
                                .borderedProminent
                            )
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle(
                "Link Account"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .task {
                if accountID == nil {
                    await create()
                }
            }
        }
    }

    @MainActor
    private func create() async {
        loading = true
        errorText = nil

        do {
            let id =
                try await AccountAPI.shared
                    .createAccount()

            accountID = id
            loading = false

        } catch {
            loading = false
            errorText =
                "Could not create WhatsApp connection."
        }
    }
}
