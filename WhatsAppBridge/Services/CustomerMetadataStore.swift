import Foundation

struct CustomerMetadata: Codable {
    var note: String = ""
    var labels: [String] = []
}

@MainActor
final class CustomerMetadataStore: ObservableObject {
    static let shared = CustomerMetadataStore()

    @Published private(set)
    var values: [String: CustomerMetadata] = [:]

    private let defaults = UserDefaults.standard
    private let storageKey = "customer.metadata.v1"

    private init() {
        guard
            let data = defaults.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(
                [String: CustomerMetadata].self,
                from: data
            )
        else { return }

        values = decoded
    }

    func key(_ conversation: Conversation) -> String {
        (conversation.accountID ?? "default")
        + "|"
        + conversation.jid
    }

    func metadata(for conversation: Conversation) -> CustomerMetadata {
        values[key(conversation)] ?? CustomerMetadata()
    }

    func setNote(_ note: String, for conversation: Conversation) {
        var item = metadata(for: conversation)
        item.note = note
        values[key(conversation)] = item
        persist()
    }

    func addLabel(_ label: String, to conversation: Conversation) {
        let clean = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        var item = metadata(for: conversation)

        if !item.labels.contains(clean) {
            item.labels.append(clean)
        }

        values[key(conversation)] = item
        persist()
    }

    func removeLabel(_ label: String, from conversation: Conversation) {
        var item = metadata(for: conversation)
        item.labels.removeAll { $0 == label }
        values[key(conversation)] = item
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(values) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
