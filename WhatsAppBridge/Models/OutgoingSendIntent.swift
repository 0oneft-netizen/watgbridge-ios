import Foundation

struct OutgoingSendIntent {
    Hashable {

    enum Kind {
        String,
        Hashable {

        case text
        case reply
        case media
        case reaction
        case delete
        case read
    }

    let route:
        ConversationRoute

    let kind:
        Kind

    let fingerprint:
        String

    var key: String {
        route.key
        + "|"
        + kind.rawValue
        + "|"
        + fingerprint
    }
}
