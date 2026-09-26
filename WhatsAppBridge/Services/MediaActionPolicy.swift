import Foundation

enum MediaActionPolicy {
    static func allowsSave(
        message: Message
    ) -> Bool {
        MessageMediaPolicy
            .maySave(message)
        && message.mediaPath != nil
    }

    static func allowsShare(
        message: Message
    ) -> Bool {
        MessageMediaPolicy
            .mayShare(message)
        && message.mediaPath != nil
    }

    static func allowsCache(
        message: Message
    ) -> Bool {
        MessageMediaPolicy
            .mayCache(message)
    }

    static func allowsGallery(
        message: Message
    ) -> Bool {
        !MessageMediaPolicy
            .isViewOnce(message)
    }
}
