import Foundation

extension APIClient {
    func existingSessionReconnect(accountID: String, restart: Bool, workspace: String, network: URLSession = .shared) async throws -> ExistingSessionReconnectSnapshot {
        guard workspace != "signed-out", workspace == UserWorkspace.id else { throw CancellationError() }
        let request = try ExistingSessionReconnectPolicy.request(base: baseURL, accountID: accountID, restart: restart)
        let (data, response) = try await network.data(for: request)
        try Task.checkCancellation()
        guard workspace == UserWorkspace.id else { throw CancellationError() }
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw NSError(domain: "SessionReconnect", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "יש להתחבר מחדש למשתמש באפליקציה."])
        }
        guard http.statusCode == 200 else {
            throw NSError(domain: "SessionReconnect", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "לא ניתן לחדש את החיבור כרגע. החשבון וההיסטוריה נשמרו."])
        }
        let snapshot = try JSONDecoder().decode(ExistingSessionReconnectSnapshot.self, from: data)
        guard snapshot.id == accountID else { throw URLError(.badServerResponse) }
        return snapshot
    }
}
