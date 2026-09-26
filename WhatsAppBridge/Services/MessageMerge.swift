import Foundation

enum MessageMerge {
    static func normalized(
        _ input: [Message]
    ) -> [Message] {
        var seen = Set<String>()
        var result: [Message] = []

        for message in input {
            let account =
                message.accountID
                ?? "default"

            let key =
                account
                + "|"
                + message.messageID

            guard
                seen.insert(key).inserted
            else {
                continue
            }

            result.append(message)
        }

        return result.sorted {
            if $0.createdAt ==
                $1.createdAt {
                return $0.id < $1.id
            }

            return $0.createdAt <
                $1.createdAt
        }
    }

    static func changed(
        old: [Message],
        new: [Message]
    ) -> Bool {
        guard
            old.count == new.count
        else {
            return true
        }

        for index in old.indices {
            let a = old[index]
            let b = new[index]

            if a.id != b.id ||
                a.messageID != b.messageID ||
                a.text != b.text ||
                a.reaction != b.reaction ||
                a.deletedRemote !=
                    b.deletedRemote ||
                a.deletedLocal !=
                    b.deletedLocal {
                return true
            }
        }

        return false
    }
}
