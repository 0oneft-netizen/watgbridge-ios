import Foundation

enum MessageContentDetector {
    static func links(in text: String) -> [URL] {
        guard
            let detector = try? NSDataDetector(
                types: NSTextCheckingResult.CheckingType.link.rawValue
            )
        else {
            return []
        }

        let range = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )

        return detector
            .matches(
                in: text,
                options: [],
                range: range
            )
            .compactMap(\.url)
    }

    static func links(in messages: [Message]) -> [URL] {
        var seen = Set<String>()
        var result: [URL] = []

        for message in messages {
            for url in links(in: message.text) {
                guard seen.insert(url.absoluteString).inserted else {
                    continue
                }

                result.append(url)
            }
        }

        return result
    }
}
