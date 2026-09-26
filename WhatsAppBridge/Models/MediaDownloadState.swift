import Foundation

enum MediaDownloadState {
    Equatable {

    case idle
    case downloading
    case ready(URL)
    case failed(String)
}
