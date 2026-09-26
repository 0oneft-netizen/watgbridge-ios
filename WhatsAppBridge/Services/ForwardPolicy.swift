import Foundation

enum ForwardPolicy {
    static func mayForward(
        _ message:
            Message
    ) -> Bool {

        !(message.deletedRemote ?? false)
        &&
        MediaOperationPolicy
            .mayForward(
                message
            )
    }
}
