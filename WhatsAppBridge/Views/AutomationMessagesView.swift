import SwiftUI

struct GreetingMessageView: View {
    @AppStorage("businessGreetingEnabled")
    private var enabled = false

    @AppStorage("businessGreetingText")
    private var message =
        "Hi! Thanks for contacting us. How can we help?"

    var body: some View {
        Form {
            Toggle(
                "Send Greeting Message",
                isOn: $enabled
            )

            Section("Message") {
                TextEditor(
                    text: $message
                )
                .frame(
                    minHeight: 140
                )
            }

            Section {
                Text(
                    "This will be connected to the WhatsApp message automation engine in the next backend pack."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(
            "Greeting Message"
        )
    }
}

struct AwayMessageView: View {
    @AppStorage("businessAwayEnabled")
    private var enabled = false

    @AppStorage("businessAwayText")
    private var message =
        "Thanks for your message. We're currently unavailable and will reply soon."

    @AppStorage("businessAwaySchedule")
    private var schedule =
        "Always"

    var body: some View {
        Form {
            Toggle(
                "Send Away Message",
                isOn: $enabled
            )

            Section("Message") {
                TextEditor(
                    text: $message
                )
                .frame(
                    minHeight: 140
                )
            }

            Section("Schedule") {
                Picker(
                    "Schedule",
                    selection: $schedule
                ) {
                    Text("Always")
                        .tag("Always")

                    Text("Outside Business Hours")
                        .tag(
                            "Outside Business Hours"
                        )

                    Text("Custom Schedule")
                        .tag(
                            "Custom Schedule"
                        )
                }
            }
        }
        .navigationTitle(
            "Away Message"
        )
    }
}
