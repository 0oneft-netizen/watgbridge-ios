import Foundation

enum NotificationCapability {
    static let followUpLocalNotifications =
        true

    // Incoming WhatsApp notifications while the
    // application is killed still require a real
    // background push path such as APNs/PWA.
    static let killedAppIncomingMessages =
        false
}
