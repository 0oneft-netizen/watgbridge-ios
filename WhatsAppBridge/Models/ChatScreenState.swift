import Foundation

struct ChatScreenState {
    Equatable {

    var loading =
        false

    var sending =
        false

    var sendingMedia =
        false

    var searching =
        false

    var error:
        String?

    var canInteract:
        Bool {

        !loading
    }
}
