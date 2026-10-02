import SwiftUI

struct BusinessShellView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            ConversationsView()
                .tabItem {
                    Label(
                        "Chats",
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
                        "Customers",
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
                        "Catalog",
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
                        "Business",
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
                        "Settings",
                        systemImage:
                            selection == 4
                            ? "gearshape.fill"
                            : "gearshape"
                    )
                }
                .tag(4)
        }
        .tint(WhatsAppVisualDesign.accent)
        .toolbarBackground(WhatsAppVisualDesign.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
