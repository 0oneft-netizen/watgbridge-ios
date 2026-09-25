import Foundation
import UserNotifications

struct PushStatus {
    let authorization: String
    let alerts: String
    let sound: String
    let badge: String
}

enum PushDiagnostics {
    static func status() async -> PushStatus {
        let settings =
            await UNUserNotificationCenter
                .current()
                .notificationSettings()

        func value(
            _ setting:
                UNNotificationSetting
        ) -> String {
            switch setting {
            case .enabled:
                return "Enabled"

            case .disabled:
                return "Disabled"

            case .notSupported:
                return "Not Supported"

            @unknown default:
                return "Unknown"
            }
        }

        let auth: String

        switch settings.authorizationStatus {
        case .authorized:
            auth = "Authorized"

        case .denied:
            auth = "Denied"

        case .notDetermined:
            auth = "Not Determined"

        case .provisional:
            auth = "Provisional"

        case .ephemeral:
            auth = "Ephemeral"

        @unknown default:
            auth = "Unknown"
        }

        return PushStatus(
            authorization: auth,
            alerts: value(
                settings.alertSetting
            ),
            sound: value(
                settings.soundSetting
            ),
            badge: value(
                settings.badgeSetting
            )
        )
    }
}
