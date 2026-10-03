import SwiftUI

struct SessionsManagementView: View {
    @ObservedObject
    private var directory =
        SessionDirectory.shared

    @State private var pendingDelete:
        SessionIdentity?

    @State private var deleteError:
        String?

    @State private var isDeleting = false

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppVisualDesign.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Runtime Build")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(BuildIdentity.marker)
                            .font(.system(
                                size: 12,
                                weight: .semibold,
                                design: .monospaced
                            ))
                    }

                    Spacer()

                    Text("Build \(BuildIdentity.code)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

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
                        .swipeActions(
                            edge: .trailing,
                            allowsFullSwipe: false
                        ) {
                            if session.id != "default" {
                                Button(
                                    role: .destructive
                                ) {
                                    pendingDelete = session
                                } label: {
                                    Label(
                                        "Delete",
                                        systemImage: "trash"
                                    )
                                }
                            }
                        }
                        .contextMenu {
                            if session.id != "default" {
                                Button(
                                    role: .destructive
                                ) {
                                    pendingDelete = session
                                } label: {
                                    Label(
                                        "Delete Session",
                                        systemImage: "trash"
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SessionNetworkDirectoryView() } label: {
                    Image(systemName: "network")
                }.accessibilityLabel("חיבור ו־IP לסשנים")
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
        .confirmationDialog(
            "Delete this session?",
            isPresented:
                Binding(
                    get: {
                        pendingDelete != nil
                    },
                    set: { presented in
                        if !presented && !isDeleting {
                            pendingDelete = nil
                        }
                    }
                ),
            titleVisibility: .visible
        ) {
            if let session = pendingDelete,
               session.id != "default" {
                Button(
                    "Delete Session and Local History",
                    role: .destructive
                ) {
                    Task {
                        await deleteSession(session)
                    }
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
                pendingDelete = nil
            }
        } message: {
            if let session = pendingDelete {
                Text(
                    "This removes \(session.effectiveName) and its local history from this app. Other WhatsApp sessions are not affected."
                )
            }
        }
        .alert(
            "Could Not Delete Session",
            isPresented:
                Binding(
                    get: {
                        deleteError != nil
                    },
                    set: { presented in
                        if !presented {
                            deleteError = nil
                        }
                    }
                )
        ) {
            Button(
                "OK",
                role: .cancel
            ) {
                deleteError = nil
            }
        } message: {
            Text(deleteError ?? "")
        }
    }

    @MainActor
    private func deleteSession(
        _ session: SessionIdentity
    ) async {
        guard
            session.id != "default",
            !isDeleting
        else {
            return
        }

        isDeleting = true
        deleteError = nil

        defer {
            isDeleting = false
        }

        do {
            try await APIClient.shared
                .deleteSession(
                    accountID:
                        session.id,
                    deleteHistory:
                        true
                )

            pendingDelete = nil

            await directory.refresh()
        } catch {
            deleteError =
                error.localizedDescription
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
