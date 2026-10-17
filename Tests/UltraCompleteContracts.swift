import Foundation
import CryptoKit

enum UserWorkspace {
    static var id = "alice"
    static let namespace = "ultra-complete-contracts-" + UUID().uuidString
    static let serverURL = URL(string: "https://unit.invalid")!
    static var baseURL: URL { serverURL.appendingPathComponent("u").appendingPathComponent(id) }
    static var defaults: UserDefaults { UserDefaults(suiteName: namespace + "." + id)! }
}
@main struct UltraCompleteContracts {
    @MainActor static func main() async throws {
        precondition(UltraLanguagePolicy.skipHebrew("שלום עולם 123", target: "he"))
        precondition(!UltraLanguagePolicy.skipHebrew("שלום hello", target: "he"))
        precondition(!UltraLanguagePolicy.skipHebrew("שלום", target: "ru"))
        precondition(UltraLanguagePolicy.detected("This is a sufficiently long English message for the customer") == "en")
        let prefs = try JSONDecoder().decode(UltraChatPreferences.self, from: Data("{\"account_id\":\"a\",\"jid\":\"1@s.whatsapp.net\",\"language\":\"ru\",\"manual\":true,\"auto_translate\":true,\"mute_until\":0,\"reset_legacy_mute\":false,\"found\":true,\"change\":\"\"}".utf8))
        precondition(prefs.manual && prefs.autoTranslate && prefs.language == "ru")
        UserWorkspace.defaults.set("shop", forKey: "ultra.signature")
        UserWorkspace.defaults.set("sensitive", forKey: "password")
        UserWorkspace.defaults.set("secret", forKey: "token")
        UserWorkspace.defaults.set("ru", forKey: "ultra.language.a|1@s.whatsapp.net")
        let backup = UltraSettingsBackupPolicy.snapshot(UserWorkspace.defaults)
        precondition(backup["ultra.signature"] as? String == "shop" && backup["password"] == nil && backup["token"] == nil)
        UserWorkspace.id = "bob"
        precondition(UltraSettingsBackupPolicy.snapshot(UserWorkspace.defaults)["ultra.signature"] == nil)
        do {
            let _: [UltraLoginDevice] = try await UltraCompleteAPI.request("auth/devices", workspace: "alice")
            preconditionFailure("stale view reached device endpoint")
        } catch is CancellationError { }
        UserWorkspace.id = "alice"
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = MediaCache(directory: root)
        func cached(_ user: String, _ id: String, _ chat: String) async throws -> URL {
            let remote = URL(string: "https://unit.invalid/u/\(user)/media?id=\(id)&account_id=a")!
            let hash = SHA256.hash(data: Data(remote.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
            let path = root.appendingPathComponent(hash).appendingPathExtension("mp4")
            try Data("existing cached bytes".utf8).write(to: path)
            return try await cache.localURL(remoteURL: remote, messageID: "a_"+id, fileName: "clip.mp4", mimeType: "video/mp4", chatJID: chat)
        }
        let kept = try await cached("alice","kept","chat1")
        let pinned = try await cached("alice","pinned","chat1")
        let removable = try await cached("alice","delete","chat1")
        let otherChat = try await cached("alice","other","chat2")
        let bob = try await cached("bob","own","chat1")
        try await cache.keepStorageFile(kept.lastPathComponent, workspace: "alice", kept: true)
        let removed = try await cache.cleanStorage(workspace: "alice", account: "a", chat: "chat1", protectedKeys: ["a|pinned"])
        precondition(removed > 0 && !FileManager.default.fileExists(atPath: removable.path))
        for file in [kept,pinned,otherChat,bob] { precondition(FileManager.default.fileExists(atPath: file.path)) }
        UserWorkspace.id = "bob"
        let hidden = await cache.storageChats(workspace: "alice", protectedKeys: [])
        precondition(hidden.isEmpty)
        do { _ = try await cache.cleanStorage(workspace: "alice", protectedKeys: []); preconditionFailure("cross-user cache cleaned") } catch is CancellationError { }
        let visible = await cache.storageChats(workspace: "bob", protectedKeys: [])
        precondition(visible.count == 1 && visible[0].files.count == 1)
        for user in ["alice","bob"] { UserDefaults.standard.removePersistentDomain(forName: UserWorkspace.namespace + "." + user) }
        print("PASS: Hebrew skip and language recognition, private preference models, credentials excluded from backup, stale user request blocked, per-chat cache cleanup protects kept/pinned/other-chat/other-user files")
    }
}
