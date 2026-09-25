import SwiftUI

struct WhatsAppConnectionSetupView: View {
    @Environment(\.dismiss)
    private var dismiss

    let type: WhatsAppConnectionType

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(
                    systemName: type.icon
                )
                .font(
                    .system(size: 64)
                )
                .foregroundStyle(
                    Color.accentColor
                )

                Text(type.title)
                    .font(.title.bold())

                if type == .business {
                    Text(
                        "The QR code will be scanned from WhatsApp Business → Settings → Linked Devices → Link a Device."
                    )
                    .multilineTextAlignment(
                        .center
                    )
                    .foregroundStyle(
                        .secondary
                    )
                } else {
                    Text(
                        "The QR code will be scanned from WhatsApp → Settings → Linked Devices → Link a Device."
                    )
                    .multilineTextAlignment(
                        .center
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                Label(
                    "Server pairing will be created for \(type.title)",
                    systemImage:
                        "server.rack"
                )
                .font(.subheadline)

                Spacer()
            }
            .padding(30)
            .navigationTitle(
                "Link Account"
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
        }
    }
}
