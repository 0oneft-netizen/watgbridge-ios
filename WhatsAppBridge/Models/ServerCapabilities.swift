import Foundation

struct ServerCapabilities:
    Equatable {

    var accountAwareMessages =
        true

    var accountAwareMedia =
        true

    var reactions =
        true

    var replies =
        true

    var deleteEveryone =
        true

    var conversationActions =
        true

    var accountRename =
        true

    var accountStatus =
        true

    // Keep false until server receipts are
    // actually persisted and exposed.
    var deliveryReceipts =
        false

    // Keep false until presence transport
    // exists end-to-end.
    var presence =
        false

    // Keep false until real incoming push
    // path is implemented.
    var killedAppPush =
        false
}
