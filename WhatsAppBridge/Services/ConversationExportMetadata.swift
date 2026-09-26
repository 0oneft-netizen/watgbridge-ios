import Foundation

struct ConversationExportMetadata {
    Equatable {

    let messageCount: Int
    let exportableCount: Int
    let excludedViewOnce: Int
}

enum ConversationExportInspector {
    static func inspect(
        _ messages:
            [Message]
    ) -> ConversationExportMetadata {

        let exportable =
            messages.filter {
                ConversationExportPolicy
                    .mayExport($0)
            }

        return
            ConversationExportMetadata(
                messageCount:
                    messages.count,
                exportableCount:
                    exportable.count,
                excludedViewOnce:
                    messages.count
                    -
                    exportable.count
            )
    }
}
