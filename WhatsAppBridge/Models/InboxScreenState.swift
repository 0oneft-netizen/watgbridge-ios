import Foundation

struct InboxScreenState:
    Equatable {

    var loading =
        false

    var refreshing =
        false

    var searchText =
        ""

    var selectedAccount:
        InboxAccountFilter =
            .all

    var error:
        String?
}
