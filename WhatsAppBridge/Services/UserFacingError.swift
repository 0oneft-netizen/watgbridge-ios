import Foundation

enum UserFacingError {
    static func message(
        for error: Error
    ) -> String {
        if let url =
            error as? URLError {

            switch url.code {
            case .notConnectedToInternet:
                return "No internet connection."

            case .timedOut:
                return "The request timed out. Try again."

            case .cannotConnectToHost,
                 .networkConnectionLost:
                return "Connection to the messaging server was lost."

            default:
                break
            }
        }

        let raw =
            error.localizedDescription

        if raw.isEmpty {
            return "Something went wrong."
        }

        return raw
    }
}
