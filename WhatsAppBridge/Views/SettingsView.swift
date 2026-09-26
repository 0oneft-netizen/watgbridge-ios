import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppSettings.notificationsEnabled)
    private var notificationsEnabled = true

    @AppStorage(AppSettings.notificationPreview)
    private var notificationPreview = true

    @AppStorage(AppSettings.notificationSound)
    private var notificationSound = true

    @AppStorage(AppSettings.badgeEnabled)
    private var badgeEnabled = true

    @AppStorage(AppSettings.hapticsEnabled)
    private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle(
                        "Notifications",
                        isOn: $notificationsEnabled
                    )

                    Toggle(
                        "Show message preview",
                        isOn: $notificationPreview
                    )
                    .disabled(!notificationsEnabled)

                    Toggle(
                        "Sound",
                        isOn: $notificationSound
                    )
                    .disabled(!notificationsEnabled)

                    Toggle(
                        "App badge",
                        isOn: $badgeEnabled
                    )
                }

                Section("WhatsApp Accounts") {
                    NavigationLink {
                        SessionsManagementView()
                    } label: {
                        Label(
                            "Sessions",
                            systemImage: "iphone.gen3"
                        )
                    }
                }

                Section("Business Tools") {
                    NavigationLink {
                        QuickRepliesView()
                    } label: {
                        Label(
                            "Quick Replies",
                            systemImage:
                                "text.bubble"
                        )
                    }
                }

                Section("Notification Diagnostics") {
                    NavigationLink {
                        PushDiagnosticsView()
                    } label: {
                        Label(
                            "Push Diagnostics",
                            systemImage:
                                "bell.badge.fill"
                        )
                    }
                }

                Section("Experience") {
                    Toggle(
                        "Haptic feedback",
                        isOn: $hapticsEnabled
                    )
                }

                Section("Connection") {
                    LabeledContent(
                        "Server",
                        value: "Connected"
                    )

                    LabeledContent(
                        "Realtime",
                        value: "Enabled"
                    )
                }

                Section("About") {
                    LabeledContent(
                        "App",
                        value: "WhatsApp Bridge"
                    )

                    LabeledContent(
                        "Version",
                        value:
                            Bundle.main.infoDictionary?[
                                "CFBundleShortVersionString"
                            ] as? String ?? "1.0"
                    )
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
