import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss)
    private var dismiss

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

    @ObservedObject
    private var sessions = SessionDirectory.shared

    var body: some View {
        NavigationStack {
            List {
                accountSection

                Section {
                    NavigationLink {
                        SessionsManagementView()
                    } label: {
                        settingsRow(
                            icon: "iphone.gen3",
                            title: "WhatsApp Accounts",
                            subtitle:
                                sessionSummary,
                            tint:
                                AppVisualDesign.accent
                        )
                    }

                    NavigationLink {
                        QuickRepliesView()
                    } label: {
                        settingsRow(
                            icon:
                                "text.bubble.fill",
                            title:
                                "Quick Replies",
                            subtitle:
                                "Saved business responses",
                            tint: .blue
                        )
                    }
                }

                Section("Notifications") {
                    Toggle(
                        "Notifications",
                        isOn:
                            $notificationsEnabled
                    )

                    Toggle(
                        "Show Message Preview",
                        isOn:
                            $notificationPreview
                    )
                    .disabled(
                        !notificationsEnabled
                    )

                    Toggle(
                        "Sounds",
                        isOn:
                            $notificationSound
                    )
                    .disabled(
                        !notificationsEnabled
                    )

                    Toggle(
                        "Badge",
                        isOn:
                            $badgeEnabled
                    )
                }

                Section("App") {
                    NavigationLink {
                        AppLockSettingsView()
                    } label: {
                        Label("נעילת אפליקציה", systemImage: "lock.shield")
                    }

                    Toggle(
                        "Haptic Feedback",
                        isOn:
                            $hapticsEnabled
                    )

                    NavigationLink {
                        PushDiagnosticsView()
                    } label: {
                        settingsRow(
                            icon:
                                "bell.badge.fill",
                            title:
                                "Notification Diagnostics",
                            subtitle:
                                "Delivery and registration status",
                            tint: .orange
                        )
                    }
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
                        value:
                            "WhatsApp Bridge"
                    )

                    LabeledContent(
                        "Version",
                        value: version
                    )
                }
            }
            .listStyle(.insetGrouped)
            .modifier(WhatsAppListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(
                .large
            )
            .tint(
                AppVisualDesign.accent
            )
            .task {
                if sessions.sessions.isEmpty {
                    await sessions.refresh()
                }
            }
        }
    }

    private var accountSection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            AppVisualDesign
                                .accent
                                .opacity(0.13)
                        )

                    Image(
                        systemName:
                            "message.fill"
                    )
                    .font(
                        .system(
                            size: 25,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        AppVisualDesign.accent
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
                    Text("Messaging Bridge")
                        .font(
                            .title3
                                .weight(.semibold)
                        )

                    Text(sessionSummary)
                        .font(.subheadline)
                        .foregroundStyle(
                            .secondary
                        )
                }

                Spacer()
            }
            .padding(.vertical, 5)
        }
    }

    private var sessionSummary: String {
        let values =
            Array(sessions.sessions.values)

        let connected =
            values.filter {
                $0.status
                    .lowercased()
                    == "connected"
            }.count

        if values.isEmpty {
            return "No linked accounts"
        }

        if connected == values.count {
            return values.count == 1
                ? "1 connected account"
                : "\(values.count) connected accounts"
        }

        return "\(connected) of \(values.count) connected"
    }

    @ViewBuilder
    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 5,
                    style: .continuous
                )
                .fill(tint)

                Image(
                    systemName: icon
                )
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)
            }
            .frame(
                width: 30,
                height: 30
            )

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(title)
                    .foregroundStyle(
                        .primary
                    )

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var version: String {
        Bundle.main
            .infoDictionary?[
                "CFBundleShortVersionString"
            ] as? String ?? "1.0"
    }
}
