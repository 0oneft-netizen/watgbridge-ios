import SwiftUI

struct WhatsAppPairingView: View {
    @Environment(\.dismiss)
    private var dismiss

    let accountID: String
    let type: WhatsAppConnectionType

    @State private var qrText = ""
    @State private var status = "Connecting…"
    @State private var errorText: String?
    @State private var pollCount = 0

    init(
        accountID: String,
        type: WhatsAppConnectionType = .personal,
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

                    Text("Link \(appName)")
                        .font(.title2.bold())

                    Group {
                        if !qrText.isEmpty {
                            QRCodeView(
                                value: qrText
                            )
                            .id(qrText)
                        } else {
                            ZStack {
                                RoundedRectangle(
                                    cornerRadius: 18,
                                    style: .continuous
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
                                width: 306,
                                height: 306
                            )
                        }
                    }

                    if !qrText.isEmpty {
                        Label(
                            "QR ready to scan",
                            systemImage:
                                "checkmark.circle.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(.green)

                        Text(
                            "Open \(appName) on your phone and scan this code."
                        )
                        .multilineTextAlignment(
                            .center
                        )
                    }

                    VStack(spacing: 8) {
                        Text(displayStatus)
                            .font(
                                .subheadline.bold()
                            )

                        if type == .business {
                            Text(
                                "WhatsApp Business → Settings → Linked Devices → Link a Device"
                            )
                            .multilineTextAlignment(
                                .center
                            )
                        } else {
                            Text(
                                "WhatsApp → Settings → Linked Devices → Link a Device"
                            )
                            .multilineTextAlignment(
                                .center
                            )
                        }
                    }
                    .foregroundStyle(.secondary)

                    if !qrText.isEmpty {
                        Text(
                            "Pairing payload received • \(qrText.utf8.count) bytes"
                        )
                        .font(.caption2)
                        .foregroundStyle(
                            .tertiary
                        )
                    }

                    if let errorText {
                        Text(errorText)
                            .font(.caption)
                            .foregroundStyle(
                                .red
                            )

                        Button("Retry") {
                            Task {
                                await pollOnce()
                            }
                        }
                        .buttonStyle(.bordered)
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
            .task(id: accountID) {
                await pollingLoop()
            }
        }
    }

    private var displayStatus: String {
        switch status.lowercased() {
        case "connecting":
            return "Connecting to WhatsApp…"

        case "waiting_qr":
            return qrText.isEmpty
                ? "Waiting for QR…"
                : "Scan QR to continue"

        case "connected":
            return "Connected successfully"

        case "qr_timeout":
            return "QR expired"

        case "error":
            return "Connection error"

        default:
            return status
        }
    }

    @MainActor
    private func pollingLoop() async {
        while !Task.isCancelled {
            await pollOnce()

            if status.lowercased()
                == "connected" {
                Haptics.success()

                try? await Task.sleep(
                    for: .milliseconds(900)
                )

                dismiss()
                return
            }

            try? await Task.sleep(
                for: .milliseconds(700)
            )
        }
    }

    @MainActor
    private func pollOnce() async {
        pollCount += 1

        do {
            var components =
                URLComponents(
                    string:
                        "https://5jjltkwg.tail256e07.ts.net/accounts/qr"
                )!

            components.queryItems = [
                URLQueryItem(
                    name: "id",
                    value: accountID
                ),

                // Prevent any intermediary
                // from serving stale QR JSON.
                URLQueryItem(
                    name: "_",
                    value: String(pollCount)
                )
            ]

            var request =
                URLRequest(
                    url: components.url!
                )

            request.cachePolicy =
                .reloadIgnoringLocalCacheData

            request.timeoutInterval = 10

            let (data, response) =
                try await URLSession.shared
                    .data(for: request)

            guard
                let http =
                    response
                        as? HTTPURLResponse,
                (200...299).contains(
                    http.statusCode
                )
            else {
                throw URLError(
                    .badServerResponse
                )
            }

            guard
                let json =
                    try JSONSerialization
                        .jsonObject(
                            with: data
                        )
                        as? [String: Any]
            else {
                throw URLError(
                    .cannotParseResponse
                )
            }

            let newStatus =
                json["status"] as? String
                ?? "waiting_qr"

            let newQR =
                json["qr"] as? String
                ?? ""

            status = newStatus

            if !newQR.isEmpty {
                qrText = newQR
                errorText = nil
            }

            if newStatus.lowercased()
                == "qr_timeout" {
                qrText = ""
            }

        } catch {
            errorText =
                "Could not refresh QR: \(error.localizedDescription)"
        }
    }
}
