import Foundation

enum AppErrorPresentation {
    static func message(
        for error: Error
    ) -> String {
        if let urlError =
            error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection."

            case .timedOut:
                return "The request timed out."

            case .cannotConnectToHost,
                 .cannotFindHost:
                return "Can't reach the server."

            default:
                break
            }
        }

        return error.localizedDescription
    }
}
