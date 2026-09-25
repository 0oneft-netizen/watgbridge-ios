import SwiftUI

struct UnifiedInboxInfoView: View {
    var body: some View {
        List {
            Section {
                VStack(
                    alignment: .center,
                    spacing: 12
                ) {
                    Image(
                        systemName:
                            "rectangle.stack.fill"
                    )
                    .font(.system(size: 42))
                    .foregroundStyle(
                        ChatDesign.accent
                    )

                    Text("Unified Chat")
                        .font(.title2.bold())

                    Text(
                        "All linked numbers can appear in one continuous timeline."
                    )
                    .multilineTextAlignment(
                        .center
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(.vertical, 15)
            }

            Section("Routing") {
                Label(
                    "Every message keeps its account",
                    systemImage:
                        "person.crop.circle.badge.checkmark"
                )

                Label(
                    "Every message keeps its destination",
                    systemImage:
                        "phone.connection"
                )

                Label(
                    "Replies return through the original account",
                    systemImage:
                        "arrowshape.turn.up.left.fill"
                )

                Label(
                    "Media stays attached to the source message",
                    systemImage:
                        "photo.on.rectangle"
                )
            }

            Section("Supported") {
                Label(
                    "Text and replies",
                    systemImage:
                        "message.fill"
                )

                Label(
                    "Photos and videos",
                    systemImage:
                        "photo.fill"
                )

                Label(
                    "Voice and audio",
                    systemImage:
                        "waveform"
                )

                Label(
                    "Documents",
                    systemImage:
                        "doc.fill"
                )

                Label(
                    "Reactions",
                    systemImage:
                        "heart.fill"
                )
            }
        }
        .navigationTitle(
            "Unified Chat"
        )
    }
}
