import Foundation

@MainActor
final class PersistentDraftStore:
    ObservableObject {

    static let shared =
        PersistentDraftStore()

    @Published
    private(set)
    var drafts:
        [String: String]

    private let storageKey =
        "watgbridge.chat.drafts.v2"

    private init() {
        if let data =
            UserDefaults.standard
                .data(
                    forKey:
                        storageKey
                ),
           let decoded =
            try? JSONDecoder()
                .decode(
                    [String: String].self,
                    from:
                        data
                ) {

            drafts =
                decoded

        } else {
            drafts = [:]
        }
    }

    func text(
        conversation:
            Conversation
    ) -> String {

        drafts[
            ConversationDraftKey
                .value(
                    conversation
                )
        ]
        ?? ""
    }

    func set(
        _ text: String,
        conversation:
            Conversation
    ) {
        let key =
            ConversationDraftKey
                .value(
                    conversation
                )

        if text
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty {

            drafts.removeValue(
                forKey:
                    key
            )

        } else {
            drafts[key] =
                text
        }

        persist()
    }

    func clear(
        conversation:
            Conversation
    ) {
        drafts.removeValue(
            forKey:
                ConversationDraftKey
                    .value(
                        conversation
                    )
        )

        persist()
    }

    private func persist() {
        guard
            let data =
                try? JSONEncoder()
                    .encode(
                        drafts
                    )
        else {
            return
        }

        UserDefaults.standard
            .set(
                data,
                forKey:
                    storageKey
            )
    }
}
