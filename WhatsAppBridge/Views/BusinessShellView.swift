import SwiftUI

struct BusinessShellView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {

            ConversationsView()
                .tabItem {
                    Label(
                        "Chats",
                        systemImage: "message.fill"
                    )
                }
                .tag(0)

            CustomersView()
                .tabItem {
                    Label(
                        "Customers",
                        systemImage: "person.2.fill"
                    )
                }
                .tag(1)

            CatalogView()
                .tabItem {
                    Label(
                        "Catalog",
                        systemImage: "bag.fill"
                    )
                }
                .tag(2)

            BusinessToolsView()
                .tabItem {
                    Label(
                        "Business",
                        systemImage: "briefcase.fill"
                    )
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label(
                        "Settings",
                        systemImage: "gearshape.fill"
                    )
                }
                .tag(4)
        }
    }
}
