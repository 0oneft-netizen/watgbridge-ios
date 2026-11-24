import Foundation

enum UserWorkspace {
    private static let lock = NSLock()
    private static var value = "owner"
    static var id: String { lock.lock(); defer { lock.unlock() }; return value }
    static func select(_ id: String) { lock.lock(); value = id; lock.unlock() }
}
final class APIClient {
    let baseURL: URL
    init(baseURL: URL) { self.baseURL = baseURL }
}
final class ReconnectFixture: URLProtocol {
    private static let lock = NSLock()
    private static var responseID = "wa_existing_123"
    private static var code = 200
    private static var switchUser = false
    private static var recorded: [URLRequest] = []
    static func configure(id: String = "wa_existing_123", status: Int = 200, switchUser: Bool = false) {
        lock.lock(); defer { lock.unlock() }
        responseID = id; code = status; self.switchUser = switchUser; recorded = []
    }
    static var requests: [URLRequest] { lock.lock(); defer { lock.unlock() }; return recorded }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        let id = Self.responseID, code = Self.code, flip = Self.switchUser
        Self.recorded.append(request)
        Self.lock.unlock()
        if flip { UserWorkspace.select("other-user") }
        let body = try! JSONSerialization.data(withJSONObject: ["id": id, "status": "waiting_qr", "qr": "unit-test-qr", "error": ""])
        let response = HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main struct ExistingSessionReconnectTests {
    static func check(_ value: Bool, _ label: String) throws {
        guard value else { throw NSError(domain: "ReconnectTests", code: 1, userInfo: [NSLocalizedDescriptionKey: label]) }
        print("PASS:", label)
    }
    static func main() async throws {
        let base = URL(string: "https://ultrav1.duckdns.org/u/owner")!
        let id = "wa_existing_123"
        let start = try ExistingSessionReconnectPolicy.request(base: base, accountID: id, restart: true)
        let poll = try ExistingSessionReconnectPolicy.request(base: base, accountID: id, restart: false)
        let startParts = URLComponents(url: start.url!, resolvingAgainstBaseURL: false)!
        let pollParts = URLComponents(url: poll.url!, resolvingAgainstBaseURL: false)!
        try check(start.httpMethod == "GET" && startParts.path == "/u/owner/accounts/qr", "existing account route, no account creation POST")
        try check(startParts.queryItems?.filter { $0.name == "id" }.map(\.value) == [id], "original account ID retained")
        try check(startParts.queryItems?.contains { $0.name == "restart" && $0.value == "1" } == true, "explicit restart only for user action")
        try check(pollParts.queryItems?.contains { $0.name == "restart" } == false, "polling does not restart a live handshake")
        for bad in ["", "default", "../other", "wa/other", String(repeating: "a", count: 121), "wa_😀"] {
            var refused = false
            do { _ = try ExistingSessionReconnectPolicy.request(base: base, accountID: bad, restart: true) } catch { refused = true }
            try check(refused, "invalid/unsupported identity rejected " + bad)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ReconnectFixture.self]
        config.httpCookieStorage = nil
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let client = APIClient(baseURL: base)
        UserWorkspace.select("owner"); ReconnectFixture.configure()
        let snapshot = try await client.existingSessionReconnect(accountID: id, restart: true, workspace: "owner", network: session)
        try check(snapshot.id == id && snapshot.qr == "unit-test-qr", "actual API method decodes same account QR")
        ReconnectFixture.configure(id: "other-account")
        var mismatch = false
        do { _ = try await client.existingSessionReconnect(accountID: id, restart: false, workspace: "owner", network: session) } catch { mismatch = true }
        try check(mismatch, "wrong-account response never displayed")
        ReconnectFixture.configure(status: 401)
        var rejected = false
        do { _ = try await client.existingSessionReconnect(accountID: id, restart: false, workspace: "owner", network: session) } catch { rejected = (error as NSError).code == 401 }
        try check(rejected, "authentication rejection preserved")
        ReconnectFixture.configure(switchUser: true)
        var switched = false
        do { _ = try await client.existingSessionReconnect(accountID: id, restart: false, workspace: "owner", network: session) } catch is CancellationError { switched = true }
        try check(switched, "in-flight response discarded after workspace switch")
        ReconnectFixture.configure()
        var signedOut = false
        do { _ = try await client.existingSessionReconnect(accountID: id, restart: true, workspace: "signed-out", network: session) } catch is CancellationError { signedOut = true }
        try check(signedOut && ReconnectFixture.requests.isEmpty, "signed-out user cannot start pairing")
    }
}
