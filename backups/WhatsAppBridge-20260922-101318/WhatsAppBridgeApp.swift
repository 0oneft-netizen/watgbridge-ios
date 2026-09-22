import SwiftUI

@main
struct WhatsAppBridgeApp: App {
    var body: some Scene {
        WindowGroup {
            ConversationsView()
                .task {
                    await NotificationManager.shared
                        .requestPermission()
                }
        }
    }
}
