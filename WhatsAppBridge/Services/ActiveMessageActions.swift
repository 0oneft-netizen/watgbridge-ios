import Foundation

enum ActiveMessageActions {
    static func canReply(
        _ message:
            Message
    ) -> Bool {

        ReplyPolicy
            .mayReply(
                message
            )
    }

    static func canForward(
        _ message:
            Message
    ) -> Bool {

        ForwardPolicy
            .mayForward(
                message
            )
    }

    static func canReact(
        _ message:
            Message
    ) -> Bool {

        ReactionPolicy
            .mayReact(
                message
            )
    }

    static func canDeleteForEveryone(
        _ message:
            Message
    ) -> Bool {

        DeleteMessagePolicy
            .mayDeleteForEveryone(
                message
            )
    }
}
