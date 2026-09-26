import Foundation

enum ReactionPolicy {
    static let common =
        [
            "❤️",
            "👍",
            "😂",
            "😮",
            "😢",
            "🙏"
        ]

    static func mayReact(
        _ message:
            Message
    ) -> Bool {

        !(message.deletedRemote ?? false)
        &&
        !message.messageID
            .isEmpty
    }
}
