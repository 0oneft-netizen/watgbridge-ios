import Foundation

@MainActor
final class ChatScrollStore {
    static let shared =
        ChatScrollStore()

    private var positions:
        [String: Int64] = [:]

    func save(
        messageID: Int64,
        route: ChatRouteIdentity
    ) {
        positions[
            route.storageKey
        ] = messageID
    }

    func restore(
        route: ChatRouteIdentity
    ) -> Int64? {
        positions[
            route.storageKey
        ]
    }

    func clear(
        route: ChatRouteIdentity
    ) {
        positions.removeValue(
            forKey:
                route.storageKey
        )
    }
}
