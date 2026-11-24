import Foundation

struct ExistingSessionReconnectSnapshot: Decodable {
    let id: String
    let status: String
    let qr: String
    let error: String
}

enum ExistingSessionReconnectPolicy {
    static func managedID(_ id: String) -> Bool {
        !id.isEmpty && id != "default" && id.utf8.count <= 120 && id.utf8.allSatisfy {
            (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) || $0 == 45 || $0 == 95
        }
    }
    static func request(base: URL, accountID: String, restart: Bool) throws -> URLRequest {
        guard managedID(accountID), base.scheme == "https", base.host != nil else { throw URLError(.badURL) }
        var parts = URLComponents(url: base.appendingPathComponent("accounts/qr"), resolvingAgainstBaseURL: false)!
        parts.queryItems = [URLQueryItem(name: "id", value: accountID)]
        if restart { parts.queryItems?.append(URLQueryItem(name: "restart", value: "1")) }
        guard let url = parts.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        return request
    }
    static func explanation(_ state: String) -> String {
        switch state.lowercased() {
        case "connected": return "החשבון מחובר"
        case "waiting_qr": return "ממתין לסריקה מהמספר המקורי"
        case "connecting", "starting": return "מנסה להתחבר באמצעות הסשן השמור…"
        case "reconnect_required", "logged_out": return "נדרש קישור מחדש של אותו מספר"
        case "qr_timeout": return "קוד ה־QR פג · אפשר לחדש אותו"
        case "identity_mismatch": return "נסרק מספר אחר. ההיסטוריה לא הועברה אליו."
        case "client_outdated": return "נדרש עדכון לשירות החיבור בשרת"
        case "connection_replaced": return "החיבור הוחלף בחיבור אחר"
        case "archived": return "החשבון נמצא בארכיון"
        default: return "החשבון עדיין לא מחובר"
        }
    }
}
