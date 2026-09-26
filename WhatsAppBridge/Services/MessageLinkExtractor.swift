import Foundation

enum MessageLinkExtractor {
    static func links(
        in messages:
            [Message]
    ) -> [URL] {

        var seen =
            Set<String>()

        var result:
            [URL] = []

        for message in messages {
            guard
                !MessageMediaPolicy
                    .isViewOnce(
                        message
                    )
            else {
                continue
            }

            let text =
                message.text

            guard
                let detector =
                    try? NSDataDetector(
                        types:
                            NSTextCheckingResult
                                .CheckingType
                                .link
                                .rawValue
                    )
            else {
                continue
            }

            let range =
                NSRange(
                    text.startIndex...,
                    in: text
                )

            detector.enumerateMatches(
                in: text,
                range: range
            ) {
                match,
                _,
                _ in

                guard
                    let url =
                        match?.url
                else {
                    return
                }

                let key =
                    url.absoluteString

                guard
                    seen.insert(
                        key
                    )
                    .inserted
                else {
                    return
                }

                result.append(
                    url
                )
            }
        }

        return result
    }
}
