import Foundation

enum CustomerWorkflowStage:
    String,
    Codable,
    CaseIterable,
    Identifiable {

    case new
    case active
    case waiting
    case followUp
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new:
            return "New"
        case .active:
            return "Active"
        case .waiting:
            return "Waiting"
        case .followUp:
            return "Follow Up"
        case .done:
            return "Done"
        }
    }

    var systemImage: String {
        switch self {
        case .new:
            return "sparkles"
        case .active:
            return "message.fill"
        case .waiting:
            return "clock"
        case .followUp:
            return "bell"
        case .done:
            return "checkmark.circle.fill"
        }
    }
}

struct CustomerWorkflowData:
    Codable,
    Equatable {

    var stage:
        CustomerWorkflowStage =
            .new

    var priority: Bool =
        false

    var updatedAt:
        Date = Date()
}

@MainActor
final class CustomerWorkflowStore:
    ObservableObject {

    static let shared =
        CustomerWorkflowStore()

    @Published
    private(set)
    var values:
        [String: CustomerWorkflowData] =
            [:]

    private var defaults: UserDefaults { UserWorkspace.defaults }

    private let storageKey =
        "customer.workflow.v1"

    private init() {
        restore()
    }

    func key(
        _ conversation:
            Conversation
    ) -> String {
        (conversation.accountID
            ?? "default")
        + "|"
        + conversation.jid
    }

    func value(
        for conversation:
            Conversation
    ) -> CustomerWorkflowData {
        values[
            key(conversation)
        ]
        ?? CustomerWorkflowData()
    }

    func setStage(
        _ stage:
            CustomerWorkflowStage,
        for conversation:
            Conversation
    ) {
        var item =
            value(
                for:
                    conversation
            )

        item.stage = stage
        item.updatedAt = Date()

        values[
            key(conversation)
        ] = item

        persist()
    }

    func togglePriority(
        _ conversation:
            Conversation
    ) {
        var item =
            value(
                for:
                    conversation
            )

        item.priority.toggle()
        item.updatedAt = Date()

        values[
            key(conversation)
        ] = item

        persist()
    }

    private func persist() {
        guard
            let data =
                try? JSONEncoder()
                    .encode(values)
        else {
            return
        }

        defaults.set(
            data,
            forKey:
                storageKey
        )
    }

    private func restore() {
        guard
            let data =
                defaults.data(
                    forKey:
                        storageKey
                ),
            let decoded =
                try? JSONDecoder()
                    .decode(
                        [String:
                            CustomerWorkflowData]
                            .self,
                        from: data
                    )
        else {
            return
        }

        values = decoded
    }
    func reloadForUser() { values = [:]; restore() }

}
