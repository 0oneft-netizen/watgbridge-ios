import SwiftUI

struct OutboxView: View {
    @ObservedObject
    private var store =
        PersistentOutbox.shared

    var body: some View {
        List {
            Section {
                NavigationLink { UltraOutboxView() } label: { Label("תור השליחה החדש ובדיקת קבלה", systemImage: "tray.and.arrow.up") }
                if !store.items.isEmpty { Text("למטה מוצגות רשומות מהתור הישן. הן אינן מועברות אוטומטית כדי למנוע שליחה כפולה.").font(.caption).foregroundStyle(.secondary) }
            }
            if store.items.isEmpty {
                ContentUnavailableView(
                    "Outbox Empty",
                    systemImage:
                        "paperplane",
                    description:
                        Text(
                            "Messages waiting to retry will appear here."
                        )
                )
            }

            ForEach(
                store.items
            ) { item in

                VStack(
                    alignment:
                        .leading,
                    spacing: 5
                ) {
                    Text(
                        item.text
                    )
                    .lineLimit(4)

                    HStack {
                        Text(
                            item.createdAt
                                .formatted(
                                    date:
                                        .abbreviated,
                                    time:
                                        .shortened
                                )
                        )

                        Spacer()

                        Text(
                            "Attempts: \(item.attempts)"
                        )
                    }
                    .font(
                        .caption2
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                .swipeActions {
                    Button(
                        role:
                            .destructive
                    ) {
                        store.remove(
                            id:
                                item.id
                        )
                    } label: {
                        Label(
                            "Remove",
                            systemImage:
                                "trash"
                        )
                    }
                }
            }
        }
        .navigationTitle(
            "Outbox"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
