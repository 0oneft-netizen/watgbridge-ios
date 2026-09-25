import SwiftUI

struct WhatsAppPairingView: View {
    @Environment(\.dismiss)
    private var dismiss

    let accountID: String
    let type: WhatsAppConnectionType

    @State private var status =
        "Preparing QR…"

    @State private var qrText = ""

    @State private var errorText:
        String?

    init(
        accountID: String,
        type: WhatsAppConnectionType =
            .personal,
        initialQR: String = ""
    ) {
        self.accountID = accountID
        self.type = type
        self._qrText = State(
            initialValue: initialQR
        )
    }

    private var appName: String {
        type == .business
        ? "WhatsApp Business"
        : "WhatsApp"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(
                        systemName:
                            type == .business
                            ? "briefcase.fill"
                            : "message.fill"
                    )
                    .font(.system(size: 42))
                    .foregroundStyle(
                        Color.accentColor
                    )

                    Text(
                        "Link \(appName)"
                    )
                    .font(.title2.bold())

                    if !qrText.isEmpty {
                        QRCodeView(
                            value: qrText
                        )

                        Text(
                            "Scan this QR code now"
                        )
                        .font(.headline)
                    } else {
                        ZStack {
                            RoundedRectangle(
                                cornerRadius: 18
                            )
                            .fill(
                                Color.secondary
                                    .opacity(0.08)
                            )

                            VStack(spacing: 14) {
                                ProgressView()

                                Text(
                                    "Generating QR…"
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                        }
                        .frame(
                            width: 270,
                            height: 270
                        )
                    }

                    VStack(spacing: 8) {
                        Text(status)
                            .font(.subheadline.bold())

                        if type == .business {
                            Text(
                                "Open WhatsApp Business → Settings → Linked Devices → Link a Device"
                            )
                            .multilineTextAlignment(
                                .center
                            )
                        } else {
                            Text(
                                "Open WhatsApp → Settings → Linked Devices → Link a Device"
                            )
                            .multilineTextAlignment(
                                .center
                            )
                        }
                    }
                    .foregroundStyle(
                        .secondary
                    )

                    if let errorText {
                        Text(errorText)
                            .font(.caption)
                            .foregroundStyle(
                                .red
                            )
                    }

                    Text(
                        "Account ID: \(accountID)"
                    )
                    .font(.caption2.monospaced())
                    .foregroundStyle(
                        .tertiary
                    )
                    .textSelection(.enabled)
                }
                .padding(24)
            }
            .navigationTitle(
                "Connect Account"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .cancellationAction
                ) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await poll()
            }
        }
    }

    @MainActor
    private func poll() async {
        while !Task.isCancelled {
            do {
                let response =
                    try await AccountAPI.shared
                        .qr(
                            id: accountID
                        )

                let currentStatus =
                    response.status ??
                    "waiting"

                let currentQR =
                    response.qrValue ??
                    ""

                status = currentStatus

                if !currentQR.isEmpty {
                    qrText = currentQR
                    errorText = nil
                }

                if currentStatus
                    .lowercased() ==
                    "connected"
                {
                    Haptics.success()

                    status =
                        "Connected successfully"

                    try? await Task.sleep(
                        for: .seconds(1)
                    )

                    dismiss()
                    return
                }

            } catch {
                errorText =
                    "Waiting for QR from server…"
            }

            try? await Task.sleep(
                for: .seconds(1)
            )
        }
    }
}
