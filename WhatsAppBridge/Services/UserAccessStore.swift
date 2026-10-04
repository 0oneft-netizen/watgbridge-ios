import Foundation
import Security
import SwiftUI
import UserNotifications

struct AppUserIdentity: Codable, Equatable {
    let id: String
    let username: String
    let owner: Bool
}
private struct UserAccessCredential: Codable {
    let user: AppUserIdentity
    let token: String
    var expiresAt: Int64
}
private struct UserAccessResponse: Decodable {
    let user: AppUserIdentity
    let token: String?
    let expires_at: Int64
}
enum UserAccessError: LocalizedError {
    case rejected, unavailable, storage, password
    var errorDescription: String? {
        switch self {
        case .rejected: return "שם המשתמש, הסיסמה או קוד ההפעלה אינם תקינים."
        case .unavailable: return "לא ניתן להתחבר לשרת. בדוק את החיבור ואת Tailscale ונסה שוב."
        case .storage: return "לא ניתן לשמור את ההתחברות באחסון המאובטח."
        case .password: return "סיסמת החשבון צריכה להכיל לפחות 6 תווים ועד 72 בתים."
        }
    }
}

@MainActor
final class UserAccessStore: ObservableObject {
    static let shared = UserAccessStore()
    @Published private(set) var user: AppUserIdentity?
    @Published private(set) var checking = true
    @Published private(set) var busy = false
    @Published var error: String?
    private var credential: UserAccessCredential?
    private var epoch = 0
    private let cookieName = "__Host-watg-session"
    private let network: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieStorage = nil
        config.urlCache = nil
        return URLSession(configuration: config)
    }()
    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: (Bundle.main.bundleIdentifier ?? "com.watgbridge.ios") + ".user-access.v1",
         kSecAttrAccount as String: "session"]
    }
    private init() {
        var lookup = query
        lookup[kSecReturnData as String] = true
        var result: CFTypeRef?
        if SecItemCopyMatching(lookup as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data {
            credential = try? JSONDecoder().decode(UserAccessCredential.self, from: data)
        }
        clearCookies()
        if let saved = credential { installCookie(saved) }
    }
    private func persist(_ value: UserAccessCredential) throws {
        let data = try JSONEncoder().encode(value)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw UserAccessError.storage }
        } else if status != errSecSuccess { throw UserAccessError.storage }
    }
    private func installCookie(_ saved: UserAccessCredential) {
        let header = cookieName + "=" + saved.token + "; Path=/; Secure; HttpOnly; SameSite=Strict"
        guard let cookie = HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": header], for: UserWorkspace.serverURL).first else { return }
        HTTPCookieStorage.shared.setCookie(cookie)
    }
    private func clearCookies() {
        for cookie in HTTPCookieStorage.shared.cookies ?? [] where cookie.domain == UserWorkspace.serverURL.host {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
    private func request(_ path: String, body: [String: String]? = nil) async throws -> UserAccessResponse {
        var request = URLRequest(url: UserWorkspace.serverURL.appendingPathComponent("auth/" + path), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        if let body {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        if let token = credential?.token { request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
        let (data, response) = try await network.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw UserAccessError.unavailable }
        if http.statusCode == 401 || http.statusCode == 403 { throw UserAccessError.rejected }
        guard http.statusCode == 200 else { throw UserAccessError.unavailable }
        return try JSONDecoder().decode(UserAccessResponse.self, from: data)
    }
    func restore() async {
        guard !busy else { return }
        if credential == nil { checking = false; return }
        busy = true; let current = epoch
        defer { busy = false }
        do {
            let response = try await request("me")
            guard current == epoch, let saved = credential else { return }
            let updated = UserAccessCredential(user: response.user, token: saved.token, expiresAt: response.expires_at)
            try persist(updated)
            credential = updated; installCookie(updated)
            await enter(response.user)
            checking = false; error = nil
        } catch UserAccessError.rejected {
            await leave(); checking = false; error = "ההתחברות פגה או בוטלה. התחבר מחדש."
        } catch {
            self.error = UserAccessError.unavailable.localizedDescription
            checking = user == nil
        }
    }
    func signIn(username: String, password: String, code: String? = nil) async throws {
        guard !busy else { return }
        if code != nil && (password.count < 6 || password.utf8.count > 72) { throw UserAccessError.password }
        busy = true; defer { busy = false }
        var body = ["username": username, "password": password]
        if let code { body["code"] = code }
        let response = try await request(code == nil ? "login" : "activate", body: body)
        guard let token = response.token else { throw UserAccessError.unavailable }
        let saved = UserAccessCredential(user: response.user, token: token, expiresAt: response.expires_at)
        do { try persist(saved) } catch { clearCookies(); throw error }
        credential = saved; installCookie(saved)
        await enter(response.user); checking = false; error = nil
    }
    private func enter(_ identity: AppUserIdentity) async {
        if user?.id != identity.id {
            RealtimeClient.shared.stop()
            UserWorkspace.select(identity.id)
            UserLocalStores.reload()
            SessionDirectory.shared.resetForUser()
            CustomerCRMDirectory.shared.resetForUser()
            AppLockStore.shared.changeUser()
            user = identity
        }
    }
    func signOut() async throws {
        guard !busy, let saved = credential else { return }
        busy = true; defer { busy = false }
        var request = URLRequest(url: UserWorkspace.serverURL.appendingPathComponent("auth/logout"), timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("Bearer " + saved.token, forHTTPHeaderField: "Authorization")
        let (_, response) = try await network.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 || http.statusCode == 401 else { throw UserAccessError.unavailable }
        await leave()
    }
    private func leave() async {
        epoch += 1
        RealtimeClient.shared.stop()
        NotificationCenter.default.post(name: .userAccessEnded, object: nil)
        user = nil; credential = nil
        SecItemDelete(query as CFDictionary)
        clearCookies(); UserWorkspace.select(nil)
        UserLocalStores.reload()
        SessionDirectory.shared.resetForUser(); CustomerCRMDirectory.shared.resetForUser()
        AppLockStore.shared.changeUser()
        URLCache.shared.removeAllCachedResponses()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        try? await UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
extension Notification.Name { static let userAccessEnded = Notification.Name("userAccessEnded") }
