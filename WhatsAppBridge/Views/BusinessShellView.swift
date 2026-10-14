import SwiftUI
import UIKit

struct BusinessShellView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            ConversationsView()
                .tabItem {
                    Label(
                        "צ׳אטים",
                        systemImage:
                            selection == 0
                            ? "message.fill"
                            : "message"
                    )
                }
                .tag(0)

            CustomersView()
                .tabItem {
                    Label(
                        "לקוחות",
                        systemImage:
                            selection == 1
                            ? "person.2.fill"
                            : "person.2"
                    )
                }
                .tag(1)

            CatalogView()
                .tabItem {
                    Label(
                        "קטלוג",
                        systemImage:
                            selection == 2
                            ? "bag.fill"
                            : "bag"
                    )
                }
                .tag(2)

            BusinessToolsView()
                .tabItem {
                    Label(
                        "כלים",
                        systemImage:
                            selection == 3
                            ? "briefcase.fill"
                            : "briefcase"
                    )
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label(
                        "הגדרות",
                        systemImage:
                            selection == 4
                            ? "gearshape.fill"
                            : "gearshape"
                    )
                }
                .tag(4)
        }
        .task { await CustomerCRMDirectory.shared.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            RealtimeClient.shared.stop()
            RealtimeClient.shared.start()
            Task { await CustomerCRMDirectory.shared.refresh() }
        }
        .tint(WhatsAppVisualDesign.accent)
        .toolbarBackground(WhatsAppVisualDesign.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
