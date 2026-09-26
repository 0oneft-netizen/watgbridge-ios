import Foundation

struct SessionWorkload {
    Identifiable,
    Equatable {

    let accountID: String
    let conversations: Int
    let unread: Int
    let priority: Int
    let followUps: Int

    var id: String {
        accountID
    }
}
