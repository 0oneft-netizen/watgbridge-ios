import Foundation

enum MessageIdentity {
    static func key(
        _ message:
            Message
    ) -> String {

        MessageRouteIdentity(
            message:
                message
        )
        .key
    }
}
