import SwiftUI

struct MessageDetailsView: View {
    let message: Message

    var body: some View {
        List {
            Section("Message") {
                if !message.text.isEmpty {
                    Text(message.text)
                        .textSelection(.enabled)
                }

                LabeledContent("Type", value: message.type)

                LabeledContent(
                    "Direction",
                    value: message.fromMe ? "Outgoing" : "Incoming"
                )

                LabeledContent(
                    "Time",
                    value: Date(
                        timeIntervalSince1970:
                            TimeInterval(message.createdAt)
                    ).formatted(
                        date: .abbreviated,
                        time: .standard
                    )
                )
            }

            if let reaction = message.reaction,
               !reaction.isEmpty {
                Section("Reaction") {
                    Text(reaction)
                }
            }
        }
        .navigationTitle("Message Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}
