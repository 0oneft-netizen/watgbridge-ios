import Foundation

enum MediaOperationPolicy {
    static func mayDownload(
        _ message: Message
    ) -> Bool {
        ViewOnceSafety
            .mayPersist(message)
    }

    static func mayCache(
        _ message: Message
    ) -> Bool {
        ViewOnceSafety
            .mayCache(message)
    }

    static func maySave(
        _ message: Message
    ) -> Bool {
        ViewOnceSafety
            .maySave(message)
    }

    static func mayShare(
        _ message: Message
    ) -> Bool {
        ViewOnceSafety
            .mayShare(message)
    }

    static func mayForward(
        _ message: Message
    ) -> Bool {
        ViewOnceSafety
            .mayForward(message)
    }
}
