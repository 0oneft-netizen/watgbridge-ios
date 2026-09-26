import SwiftUI

struct CustomerProfileTools: View {
    let conversation:
        Conversation

    let messages:
        [Message]

    var body: some View {
        Section(
            "Tools"
        ) {
            NavigationLink {
                CustomerTimelineView(
                    conversation:
                        conversation,
                    messages:
                        messages
                )
            } label: {
                Label(
                    "Customer Timeline",
                    systemImage:
                        "clock.arrow.circlepath"
                )
            }

            NavigationLink {
                CustomerFollowUpView(
                    conversation:
                        conversation
                )
            } label: {
                Label(
                    "Follow Up",
                    systemImage:
                        "bell"
                )
            }

            NavigationLink {
                CustomerActivityView(
                    messages:
                        messages
                )
            } label: {
                Label(
                    "Activity",
                    systemImage:
                        "chart.bar"
                )
            }

            NavigationLink {
                ConversationExportView(
                    messages:
                        messages
                )
            } label: {
                Label(
                    "Export Chat",
                    systemImage:
                        "square.and.arrow.up"
                )
            }
        }
    }
}
