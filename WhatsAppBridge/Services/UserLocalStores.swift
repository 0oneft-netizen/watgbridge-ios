import Foundation

@MainActor
enum UserLocalStores {
    static func reload() {
        AppSettings.registerDefaults()
        PersistentOutbox.shared.reloadForUser()
        SessionQuickReplyStore.shared.reloadForUser()
        CustomerFollowUpStore.shared.reloadForUser()
        CustomerWorkflowStore.shared.reloadForUser()
        QuickReplyStore.shared.reloadForUser()
        StarredMessageStore.shared.reloadForUser()
        PersistentDraftStore.shared.reloadForUser()
        CustomerMetadataStore.shared.reloadForUser()
        ConversationLocalState.shared.reloadForUser()
        ChatScrollStore.shared.reloadForUser()
        FailedSendStore.shared.reloadForUser()
    }
}
