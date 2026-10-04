import SwiftUI

@main
struct WhatsAppBridgeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var appLock = AppLockStore.shared
    @ObservedObject private var access = UserAccessStore.shared
    @Environment(\.scenePhase) private var scenePhase

    init() { AppSettings.registerDefaults() }
    var body: some Scene {
        WindowGroup {
            Group {
                if access.checking {
                    VStack(spacing: 18) {
                        ProgressView("בודק התחברות…")
                        if let error = access.error {
                            Text(error).multilineTextAlignment(.center)
                            Button("נסה שוב") { Task { await access.restore() } }.disabled(access.busy)
                        }
                    }.padding()
                } else if let user = access.user {
                    BusinessShellView()
                        .id(user.id)
                        .defaultAppStorage(UserWorkspace.defaults)
                        .opacity(appLock.enabled && appLock.locked ? 0 : 1)
                        .allowsHitTesting(!appLock.enabled || !appLock.locked)
                        .accessibilityHidden(appLock.enabled && appLock.locked)
                        .background(AppLockWindowBridge().frame(width: 0, height: 0))
                        .task {
                            RealtimeClient.shared.start()
                            await NotificationManager.shared.requestPermission()
                            guard access.user?.id == user.id else { return }
                            NotificationManager.shared.registerForPushNotifications()
                        }
                } else {
                    UserAccessView()
                }
            }
            .task { await access.restore() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, access.user != nil { Task { await access.restore() } }
            }
        }
    }
}
