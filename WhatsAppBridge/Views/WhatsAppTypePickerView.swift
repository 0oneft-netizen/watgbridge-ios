import SwiftUI

enum WhatsAppConnectionType: String {
    case personal = "personal"
    case business = "business"

    var title: String {
        switch self {
        case .personal:
            return "WhatsApp"

        case .business:
            return "WhatsApp Business"
        }
    }

    var subtitle: String {
        switch self {
        case .personal:
            return "Connect a regular WhatsApp account"

        case .business:
            return "Connect a WhatsApp Business account"
        }
    }

    var icon: String {
        switch self {
        case .personal:
            return "message.fill"

        case .business:
            return "briefcase.fill"
        }
    }
}

struct WhatsAppTypePickerView: View {
    @Environment(\.dismiss)
    private var dismiss

    @State private var selectedType:
        WhatsAppConnectionType?

    var body: some View {
        NavigationStack {
            VStack(
                alignment: .leading,
                spacing: 22
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    Text(
                        "Connect WhatsApp"
                    )
                    .font(.largeTitle.bold())

                    Text(
                        "Choose which type of account you want to link."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                connectionButton(
                    type: .business
                )

                connectionButton(
                    type: .personal
                )

                Spacer()

                Text(
                    "Business accounts should be scanned from WhatsApp Business → Linked Devices."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(24)
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
            .sheet(
                item: $selectedType
            ) { type in
                WhatsAppConnectionSetupView(
                    type: type
                )
            }
        }
    }

    @ViewBuilder
    private func connectionButton(
        type: WhatsAppConnectionType
    ) -> some View {
        Button {
            Haptics.selection()
            selectedType = type
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 14
                    )
                    .fill(
                        Color.accentColor
                            .opacity(0.12)
                    )

                    Image(
                        systemName:
                            type.icon
                    )
                    .font(.title2)
                    .foregroundStyle(
                        Color.accentColor
                    )
                }
                .frame(
                    width: 58,
                    height: 58
                )

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text(type.title)
                        .font(.headline)

                    Text(type.subtitle)
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                }

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(
                    cornerRadius: 18
                )
                .fill(
                    Color.secondary
                        .opacity(0.07)
                )
            )
        }
        .buttonStyle(.plain)
    }
}

extension WhatsAppConnectionType:
    Identifiable
{
    var id: String {
        rawValue
    }
}
