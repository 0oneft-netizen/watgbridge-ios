import Foundation

enum MediaCacheIdentity {
    static func key(
        _ message:
            Message
    ) -> String {

        let identity =
            MessageRouteIdentity(
                message:
                    message
            )

        return identity.key
    }
}
