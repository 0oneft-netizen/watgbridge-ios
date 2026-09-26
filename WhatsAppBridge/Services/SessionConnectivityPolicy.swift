import Foundation

enum SessionConnectivityPolicy {
    static func canSend(
        status: String
    ) -> Bool {

        status.lowercased()
        ==
        "connected"
    }

    static func requiresRepair(
        status: String
    ) -> Bool {

        status.lowercased()
        ==
        "reconnect_required"
    }

    static func isOffline(
        status: String
    ) -> Bool {

        status.lowercased()
        ==
        "disconnected"
    }
}
