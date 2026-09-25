import SwiftUI

@main
struct WhatsAppBridgeApp: App {
    @UIApplicationDelegateAdaptor(
        AppDelegate.self
    )
    var appDelegate

    init() {
        AppSettings.registerDefaults()
    }

    var body: some Scene {
        WindowGroup {
            BusinessShellView()
                .task {
                    RealtimeClient.shared
                        .start()

                    await NotificationManager
                        .shared
                        .requestPermission()

                    NotificationManager
                        .shared
                        .registerForPushNotifications()
                }
        }
    }
}
