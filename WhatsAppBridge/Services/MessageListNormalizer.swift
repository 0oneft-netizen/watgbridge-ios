import Foundation

enum MessageListNormalizer {
    static func normalize(
        _ messages:
            [Message]
    ) -> [Message] {

        var values:
            [String: Message] =
                [:]

        for message in messages {
            values[
                MessageIdentity
                    .key(
                        message
                    )
            ] =
                message
        }

        return values
            .values
            .sorted {
                if $0.createdAt ==
                    $1.createdAt {

                    return $0.id <
                        $1.id
                }

                return $0.createdAt <
                    $1.createdAt
            }
    }
}
