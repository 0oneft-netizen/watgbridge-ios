import Foundation
import SwiftUI

enum AppSettings {
    static let notificationsEnabled = "notificationsEnabled"
    static let notificationPreview = "notificationPreview"
    static let notificationSound = "notificationSound"
    static let badgeEnabled = "badgeEnabled"
    static let hapticsEnabled = "hapticsEnabled"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            notificationsEnabled: true,
            notificationPreview: true,
            notificationSound: true,
            badgeEnabled: true,
            hapticsEnabled: true
        ])
    }

    static var notifications: Bool {
        UserDefaults.standard.bool(forKey: notificationsEnabled)
    }

    static var previews: Bool {
        UserDefaults.standard.bool(forKey: notificationPreview)
    }

    static var sound: Bool {
        UserDefaults.standard.bool(forKey: notificationSound)
    }

    static var badge: Bool {
        UserDefaults.standard.bool(forKey: badgeEnabled)
    }

    static var haptics: Bool {
        UserDefaults.standard.bool(forKey: hapticsEnabled)
    }
}
