import SwiftUI

struct ModernSettingsView: View {
    @AppStorage("mediaAutoDownload")
    private var mediaAutoDownload = true

    @AppStorage("notificationPreview")
    private var notificationPreview = true

    @AppStorage("saveReceivedMedia")
    private var saveReceivedMedia = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        AccountsView()
                    } label: {
                        settingsRow(
                            "person.crop.circle",
                            "Accounts",
                            "Linked WhatsApp numbers"
                        )
                    }
                }

                Section {
                    NavigationLink {
                        notificationSettings
                    } label: {
                        settingsRow(
                            "bell.fill",
                            "Notifications",
                            "Sounds, previews and badges"
                        )
                    }

                    NavigationLink {
                        storageSettings
                    } label: {
                        settingsRow(
                            "internaldrive.fill",
                            "Storage and Media",
                            "Photos, video and documents"
                        )
                    }

                    NavigationLink {
                        privacySettings
                    } label: {
                        settingsRow(
                            "lock.fill",
                            "Privacy",
                            "App and message privacy"
                        )
                    }
                }

                Section {
                    NavigationLink {
                        BusinessToolsView()
                    } label: {
                        settingsRow(
                            "briefcase.fill",
                            "Business Tools",
                            "Customers and automation"
                        )
                    }

                    NavigationLink {
                        unifiedInboxSettings
                    } label: {
                        settingsRow(
                            "rectangle.stack.fill",
                            "Unified Chat",
                            "All numbers in one conversation"
                        )
                    }
                }

                Section {
                    HStack {
                        Spacer()

                        VStack(spacing: 5) {
                            Text("WhatsApp Bridge")
                                .font(
                                    .footnote.weight(
                                        .semibold
                                    )
                                )

                            Text(
                                "Private multi-account client"
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .listRowBackground(
                        Color.clear
                    )
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func settingsRow(
        _ icon: String,
        _ title: String,
        _ subtitle: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    ChatDesign.accent
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 7
                    )
                )

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(title)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
            }
        }
    }

    private var notificationSettings: some View {
        Form {
            Section("Message Notifications") {
                Toggle(
                    "Show Preview",
                    isOn: $notificationPreview
                )

                Label(
                    "Notification Sound",
                    systemImage: "speaker.wave.2"
                )

                Label(
                    "Badges",
                    systemImage: "app.badge"
                )
            }

            Section("Chats") {
                Label(
                    "Muted Conversations",
                    systemImage: "bell.slash"
                )
            }
        }
        .navigationTitle("Notifications")
    }

    private var storageSettings: some View {
        Form {
            Section("Media") {
                Toggle(
                    "Automatic Download",
                    isOn: $mediaAutoDownload
                )

                Toggle(
                    "Save Received Media",
                    isOn: $saveReceivedMedia
                )
            }

            Section {
                Label(
                    "Manage Storage",
                    systemImage:
                        "internaldrive"
                )
            }
        }
        .navigationTitle("Storage and Media")
    }

    private var privacySettings: some View {
        Form {
            Section {
                Label(
                    "App Lock",
                    systemImage: "faceid"
                )

                Label(
                    "Read Receipts",
                    systemImage:
                        "checkmark.circle"
                )
            }

            Section("Media Privacy") {
                Text(
                    "View Once media is not cached or exported."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Privacy")
    }

    private var unifiedInboxSettings: some View {
        Form {
            Section {
                Label(
                    "One continuous conversation",
                    systemImage:
                        "rectangle.stack.fill"
                )

                Text(
                    "Messages from multiple numbers stay in one timeline while every message keeps its original account and destination."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Reply Routing") {
                Label(
                    "Reply through original number",
                    systemImage:
                        "arrowshape.turn.up.left"
                )

                Label(
                    "Show sending account",
                    systemImage:
                        "person.text.rectangle"
                )
            }
        }
        .navigationTitle("Unified Chat")
    }
}
