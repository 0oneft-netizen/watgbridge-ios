import SwiftUI

struct BusinessToolsView: View {
    var body: some View {
        NavigationStack {
            List {

                Section("WhatsApp") {
                    NavigationLink {
                        WhatsAppAccountsView()
                    } label: {
                        Label(
                            "WhatsApp Accounts",
                            systemImage:
                                "qrcode"
                        )
                    }
                }

                Section("תפוצות ואוטומציה") {
                    NavigationLink { CustomerAutomationCenter() } label: {
                        Label("מרכז תפוצות ו־AI", systemImage: "paperplane.fill")
                    }
                    NavigationLink { AutomationAudienceView(source: "stale") } label: {
                        Label("לקוחות שלא דיברו לאחרונה", systemImage: "clock.arrow.circlepath")
                    }
                    NavigationLink { CustomerAutomationSettingsView() } label: {
                        Label("מענה AI ללקוח חדש", systemImage: "sparkles")
                    }
                }

                Section("ULTRA-SAP מדיה ושליחה") {
                    NavigationLink { UltraMediaLibrary() } label: { Label("גלריה מכל המספרים", systemImage: "photo.on.rectangle") }
                    NavigationLink { UltraOutboxView() } label: { Label("תור שליחה ובדיקת מצב", systemImage: "tray.and.arrow.up") }
                }
                Section("Messaging") {
                    NavigationLink {
                        QuickRepliesView()
                    } label: {
                        Label(
                            "Quick Replies",
                            systemImage:
                                "text.bubble.fill"
                        )
                    }

                    NavigationLink {
                        GreetingMessageView()
                    } label: {
                        Label(
                            "Greeting Message",
                            systemImage:
                                "hand.wave.fill"
                        )
                    }

                    NavigationLink {
                        AwayMessageView()
                    } label: {
                        Label(
                            "Away Message",
                            systemImage:
                                "moon.fill"
                        )
                    }
                }

                Section("Customers") {
                    NavigationLink { UltraCustomerMatchesView() } label: { Label("חפש לקוח בכל החשבונות", systemImage: "magnifyingglass") }
                    NavigationLink {
                        CustomersView()
                    } label: {
                        Label(
                            "Customer Management",
                            systemImage:
                                "person.2.fill"
                        )
                    }
                }

                Section("Selling") {
                    NavigationLink {
                        CatalogView()
                    } label: {
                        Label(
                            "Catalog",
                            systemImage:
                                "bag.fill"
                        )
                    }
                }

                Section("Coming Next") {
                    Label(
                        "Business Profile",
                        systemImage: "storefront"
                    )

                    Label(
                        "Statistics",
                        systemImage: "chart.bar.fill"
                    )

                    Label(
                        "Customer Lists",
                        systemImage:
                            "person.3.sequence.fill"
                    )
                }
            }
            .navigationTitle(
                "Business Tools"
            )
        }
    }
}
