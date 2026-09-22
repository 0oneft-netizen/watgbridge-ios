import SwiftUI

@main
struct WhatsAppBridgeApp: App {
    var body: some Scene {
        WindowGroup {
            ConversationsView()
                .task {
            RealtimeClient.shared.start()

                    await NotificationManager.shared
                        .requestPermission()
                }
        }
    }
}
