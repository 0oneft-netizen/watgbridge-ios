import Foundation

enum ForwardPolicy {
    static func mayForward(
        _ message:
            Message
    ) -> Bool {

        !message.deletedRemote
        &&
        MediaOperationPolicy
            .mayForward(
                message
            )
    }
}
