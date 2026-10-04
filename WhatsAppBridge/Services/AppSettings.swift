import Foundation
import SwiftUI

enum AppSettings {
    static let notificationsEnabled = "notificationsEnabled"
    static let notificationPreview = "notificationPreview"
    static let notificationSound = "notificationSound"
    static let badgeEnabled = "badgeEnabled"
    static let hapticsEnabled = "hapticsEnabled"

    static func registerDefaults() {
        UserWorkspace.defaults.register(defaults: [
            notificationsEnabled: true,
            notificationPreview: true,
            notificationSound: true,
            badgeEnabled: true,
            hapticsEnabled: true
        ])
    }

    static var notifications: Bool {
        UserWorkspace.defaults.bool(forKey: notificationsEnabled)
    }

    static var previews: Bool {
        UserWorkspace.defaults.bool(forKey: notificationPreview)
    }

    static var sound: Bool {
        UserWorkspace.defaults.bool(forKey: notificationSound)
    }

    static var badge: Bool {
        UserWorkspace.defaults.bool(forKey: badgeEnabled)
    }

    static var haptics: Bool {
        UserWorkspace.defaults.bool(forKey: hapticsEnabled)
    }
}
