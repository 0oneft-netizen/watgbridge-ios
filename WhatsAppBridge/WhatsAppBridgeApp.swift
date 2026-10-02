import SwiftUI

@main
struct WhatsAppBridgeApp: App {
    @UIApplicationDelegateAdaptor(
        AppDelegate.self
    )
    var appDelegate

    @ObservedObject private var appLock = AppLockStore.shared

    init() {
        AppSettings.registerDefaults()
    }

    var body: some Scene {
        WindowGroup {
            BusinessShellView()
                .opacity(appLock.enabled && appLock.locked ? 0 : 1)
                .allowsHitTesting(!appLock.enabled || !appLock.locked)
                .accessibilityHidden(appLock.enabled && appLock.locked)
                .background(AppLockWindowBridge().frame(width: 0, height: 0))
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
