import SwiftUI

struct SessionsManagementView: View {
    @ObservedObject
    private var directory =
        SessionDirectory.shared

    var body: some View {
        List {
            SessionsHeaderView(
                sessions: directory.sessions
            )
            .listRowBackground(
                Color.clear
            )

            if directory.sessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions",
                    systemImage:
                        "iphone.slash",
                    description:
                        Text(
                            "Linked WhatsApp sessions will appear here."
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
                        HStack(
                            spacing: 12
                        ) {
                            ZStack {
                                Circle()
                                    .fill(
                                        Color
                                            .accentColor
                                            .opacity(
                                                0.12
                                            )
                                    )

                                Image(
                                    systemName:
                                        "iphone"
                                )
                                .foregroundStyle(
                                    Color
                                        .accentColor
                                )
                            }
                            .frame(
                                width: 42,
                                height: 42
                            )

                            VStack(
                                alignment:
                                    .leading,
                                spacing: 3
                            ) {
                                Text(
                                    session
                                        .effectiveName
                                )
                                .font(
                                    .body
                                        .weight(
                                            .medium
                                        )
                                )

                                Text(
                                    session.status
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            Spacer()

                            if session.status
                                .lowercased()
                                == "connected" {
                                Circle()
                                    .fill(.green)
                                    .frame(
                                        width: 8,
                                        height: 8
                                    )
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Sessions")
        .task {
            await directory.refresh()
        }
        .refreshable {
            await directory.refresh()
        }
    }
}
