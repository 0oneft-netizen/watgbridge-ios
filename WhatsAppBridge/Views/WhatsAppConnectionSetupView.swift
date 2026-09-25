import SwiftUI

struct WhatsAppConnectionSetupView: View {
    let type: WhatsAppConnectionType

    @State private var accountID:
        String?

    @State private var initialQR = ""

    @State private var loading = true

    @State private var errorText:
        String?

    var body: some View {
        NavigationStack {
            Group {
                if let accountID {
                    WhatsAppPairingView(
                        accountID: accountID,
                        type: type,
                        initialQR: initialQR
                    )
                } else {
                    VStack(spacing: 24) {
                        Spacer()

                        Image(
                            systemName:
                                type == .business
                                ? "briefcase.fill"
                                : "message.fill"
                        )
                        .font(
                            .system(size: 64)
                        )
                        .foregroundStyle(
                            Color.accentColor
                        )

                        Text(type.title)
                            .font(.title.bold())

                        if loading {
                            ProgressView(
                                "Contacting WhatsApp…"
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

                            Button("Try Again") {
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
            let response =
                try await AccountAPI.shared
                    .createAccount(
                        type: type
                    )

            initialQR =
                response.qr ?? ""

            accountID =
                response.id

            loading = false

        } catch {
            loading = false
            errorText =
                "Could not generate WhatsApp QR."
        }
    }
}
