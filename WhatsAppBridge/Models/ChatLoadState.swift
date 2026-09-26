import Foundation

enum ChatLoadState:
    Equatable {

    case idle
    case loading
    case loaded
    case failed(String)
}
