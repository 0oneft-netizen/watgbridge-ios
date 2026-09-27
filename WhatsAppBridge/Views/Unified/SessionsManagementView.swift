import SwiftUI

struct SessionsManagementView: View {
    @ObservedObject
    private var directory =
        SessionDirectory.shared

    var body: some View {
        List {
            Section {
                NavigationLink {
                    WhatsAppTypePickerView()
                } label: {
                    HStack(spacing: 13) {
                        ZStack {
                            Circle()
                                .fill(
                                    AppVisualDesign
                                        .accent
                                        .opacity(0.12)
                                )

                            Image(
                                systemName:
                                    "plus.message.fill"
                            )
                            .foregroundStyle(
                                AppVisualDesign.accent
                            )
                        }
                        .frame(
                            width: 44,
                            height: 44
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 2
                        ) {
                            Text("Link WhatsApp Account")
                                .font(
                                    .body.weight(.semibold)
                                )

                            Text(
                                "Regular or Business"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }

            Section("Linked Accounts") {
                if directory.sessions.isEmpty {
                    ContentUnavailableView(
                        "No linked accounts",
                        systemImage:
                            "iphone.slash",
                        description:
                            Text(
                                "Connect a WhatsApp account to start."
                            )
                    )
                } else {
                    ForEach(
                        directory.sessions
                            .values
                            .sorted {
                                $0.effectiveName
                                    .localizedCaseInsensitiveCompare(
                                        $1.effectiveName
                                    )
                                    == .orderedAscending
                            }
                    ) { session in
                        NavigationLink {
                            RenameSessionView(
                                accountID:
                                    session.id,
                                currentName:
                                    session.effectiveName,
                                phone:
                                    session.phone
                            )
                        } label: {
                            sessionRow(session)
                        }
                    }
                }
            }
        }
        .navigationTitle("WhatsApp Accounts")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await directory.refresh()
        }
        .refreshable {
            await directory.refresh()
        }
    }

    private func sessionRow(
        _ session: SessionIdentity
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        AppVisualDesign
                            .accent
                            .opacity(0.12)
                    )

                Image(
                    systemName:
                        session.accountType
                            .lowercased()
                            == "business"
                        ? "briefcase.fill"
                        : "message.fill"
                )
                .foregroundStyle(
                    AppVisualDesign.accent
                )
            }
            .frame(
                width: 46,
                height: 46
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(session.effectiveName)
                    .font(
                        .body.weight(.semibold)
                    )
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text(
                        session.accountTypeLabel
                    )

                    if !session.phone.isEmpty {
                        Text("•")

                        Text(
                            session.formattedPhone
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 6)

            statusBadge(
                session.status
            )
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(
        _ status: String
    ) -> some View {
        let connected =
            status.lowercased()
            == "connected"

        return HStack(spacing: 4) {
            Circle()
                .fill(
                    connected
                    ? Color.green
                    : Color.secondary
                )
                .frame(width: 7, height: 7)

            Text(
                connected
                ? "Connected"
                : status
                    .replacingOccurrences(
                        of: "_",
                        with: " "
                    )
                    .capitalized
            )
            .font(
                .system(
                    size: 11,
                    weight: .medium
                )
            )
        }
        .foregroundStyle(
            connected
            ? AppVisualDesign.accent
            : Color.secondary
        )
    }
}
