import Foundation

@MainActor
final class ConversationLocalState: ObservableObject {
    static let shared = ConversationLocalState()

    @Published private(set) var pinned = Set<String>()
    @Published private(set) var muted = Set<String>()
    @Published private(set) var archived = Set<String>()
    @Published private(set) var manualUnread = Set<String>()

    private let d = UserDefaults.standard

    private init() {
        pinned = load("conversation.pinned")
        muted = load("conversation.muted")
        archived = load("conversation.archived")
        manualUnread = load("conversation.unread")
    }

    func key(_ c: Conversation) -> String {
        (c.accountID ?? "default") + "|" + c.jid
    }

    func isPinned(_ c: Conversation) -> Bool { pinned.contains(key(c)) }
    func isMuted(_ c: Conversation) -> Bool { muted.contains(key(c)) }
    func isArchived(_ c: Conversation) -> Bool { archived.contains(key(c)) }
    func isUnread(_ c: Conversation) -> Bool { manualUnread.contains(key(c)) }

    func togglePin(_ c: Conversation) {
        toggle(&pinned, key(c))
        save(pinned, "conversation.pinned")
    }

    func toggleMute(_ c: Conversation) {
        toggle(&muted, key(c))
        save(muted, "conversation.muted")
    }

    func toggleArchive(_ c: Conversation) {
        toggle(&archived, key(c))
        save(archived, "conversation.archived")
    }

    func toggleUnread(_ c: Conversation) {
        toggle(&manualUnread, key(c))
        save(manualUnread, "conversation.unread")
    }

    private func toggle(_ set: inout Set<String>, _ key: String) {
        if set.contains(key) { set.remove(key) }
        else { set.insert(key) }
    }

    private func save(_ value: Set<String>, _ key: String) {
        d.set(Array(value), forKey: key)
    }

    private func load(_ key: String) -> Set<String> {
        Set(d.stringArray(forKey: key) ?? [])
    }
}
