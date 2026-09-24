import SwiftUI

@main
struct WhatsAppBridgeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
