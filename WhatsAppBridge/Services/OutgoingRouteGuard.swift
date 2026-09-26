import Foundation

enum OutgoingRouteGuard {
    static func validate(
        conversation:
            Conversation
    ) throws {

        guard
            ConversationRouteValidator
                .isValid(
                    conversation
                )
        else {
            throw RouteError
                .invalidConversation
        }
    }

    static func validate(
        message:
            Message
    ) throws {

        guard
            MessageRouteValidator
                .isValid(
                    message
                )
        else {
            throw RouteError
                .invalidMessage
        }
    }

    enum RouteError:
        LocalizedError {

        case invalidConversation
        case invalidMessage

        var errorDescription:
            String? {

            switch self {
            case .invalidConversation:
                return
                    "Conversation route is missing."

            case .invalidMessage:
                return
                    "Message route is missing."
            }
        }
    }
}
