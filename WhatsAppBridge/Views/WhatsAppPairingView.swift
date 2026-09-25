import SwiftUI

struct WhatsAppPairingView: View {
    @Environment(\.dismiss)
    private var dismiss

    let accountID: String

    @State private var status =
        "Preparing QR…"

    @State private var qrText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Image(
                    systemName:
                        "qrcode.viewfinder"
                )
                .font(
                    .system(size: 90)
                )

                Text(
                    "Link WhatsApp"
                )
                .font(.title.bold())

                Text(status)
                    .foregroundStyle(
                        .secondary
                    )

                if !qrText.isEmpty {
                    Text(qrText)
                        .font(
                            .caption.monospaced()
                        )
                        .textSelection(
                            .enabled
                        )
                }

                Text(
                    "Open WhatsApp → Linked Devices → Link a Device and scan the QR shown here."
                )
                .multilineTextAlignment(
                    .center
                )
                .font(.callout)
                .foregroundStyle(
                    .secondary
                )

                Spacer()
            }
            .padding()
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

                status = response.status
                qrText = response.qr

                if response.status ==
                    "connected"
                {
                    Haptics.success()

                    try? await Task.sleep(
                        for: .seconds(1)
                    )

                    dismiss()
                    return
                }

            } catch {
                status =
                    "Waiting for server…"
            }

            try? await Task.sleep(
                for: .seconds(1)
            )
        }
    }
}
