import Foundation
import UIKit

extension Data {
    var hexadecimalString: String {
        map {
            String(
                format: "%02x",
                $0
            )
        }
        .joined()
    }
}

extension Notification.Name {
    static let remotePushTokenUpdated =
        Notification.Name(
            "remotePushTokenUpdated"
        )
}
