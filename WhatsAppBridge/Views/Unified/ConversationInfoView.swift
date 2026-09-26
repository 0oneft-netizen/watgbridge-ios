import SwiftUI

struct ConversationInfoView: View {
    let conversation: Conversation

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    private var customerName: String {
        ChatIdentity.customerName(
            conversation: conversation
        )
    }

    private var customerPhone: String {
        CustomerIdentityPresentation
            .formattedPhone(
                from: conversation.jid
            )
    }

    private var sessionName: String {
        sessions.name(
            for: conversation.accountID
        )
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 9) {
                    AsyncImage(
                        url:
                            APIClient.shared
                                .avatarURL(
                                    for:
                                        conversation.jid
                                )
                    ) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            ZStack {
                                Circle()
                                    .fill(
                                        ChatDesign
                                            .subtleFill
                                    )

                                Text(
                                    conversation
                                        .initials
                                )
                                .font(.title2.bold())
                            }
                        }
                    }
                    .frame(
                        width: 92,
                        height: 92
                    )
                    .clipShape(Circle())

                    Text(customerName)
                        .font(.title2.bold())

                    if !customerPhone.isEmpty {
                        Text(customerPhone)
                            .foregroundStyle(
                                .secondary
                            )
                    }

                    ConversationRouteView(
                        accountID:
                            conversation.accountID
                    )
                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(.vertical, 12)
            }

            Section {
                ConversationQuickActionsView {
                    action in

                    AppHaptics.selection()

                    // Navigation/action wiring is
                    // handled by the owning chat view.
                    _ = action
                }
            }

            Section("Account") {
                LabeledContent(
                    "Session",
                    value: sessionName
                )
            }
        }
        .navigationTitle("Contact Info")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .task {
            if sessions.sessions.isEmpty {
                await sessions.refresh()
            }
        }
    }
}
