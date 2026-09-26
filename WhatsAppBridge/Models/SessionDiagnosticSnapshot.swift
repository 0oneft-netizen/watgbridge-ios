import Foundation

struct SessionDiagnosticSnapshot {
    Identifiable,
    Equatable {

    let accountID: String
    let displayName: String
    let status: String
    let accountType: String?
    let conversationCount: Int
    let unreadCount: Int

    var id: String {
        accountID
    }
}
