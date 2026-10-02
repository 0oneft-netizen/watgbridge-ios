import Foundation
import Security
import CommonCrypto
import SwiftUI

// Only a salted PBKDF2 verifier is persisted; the entered secret is never stored.
private struct AppLockRecord: Codable {
    let version: Int
    let mode: AppLockMode
    let salt: Data
    let verifier: Data
    let rounds: UInt32
    var failures: Int
    var retryAfter: Date
    var timeoutSeconds: Int? // Missing in existing credentials: immediate lock.
}

private enum AppLockCrypto {
    static func derive(_ secret: String, salt: Data, rounds: UInt32) throws -> Data {
        let password = Array(secret.utf8)
        var output = [UInt8](repeating: 0, count: 32)
        let status = password.withUnsafeBytes { p in
            salt.withUnsafeBytes { s in
                output.withUnsafeMutableBytes { o in
                    CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),
                        p.baseAddress!.assumingMemoryBound(to: Int8.self), password.count,
                        s.baseAddress!.assumingMemoryBound(to: UInt8.self), salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), rounds,
                        o.baseAddress!.assumingMemoryBound(to: UInt8.self), 32)
                }
            }
        }
        guard status == kCCSuccess else { throw AppLockFailure.storage }
        return Data(output)
    }
    static func equal(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        var difference: UInt8 = 0
        for (x, y) in zip(a, b) { difference |= x ^ y }
        return difference == 0
    }
}

private enum AppLockFailure: LocalizedError {
    case storage, invalid, mismatch, changed
    var errorDescription: String? {
        switch self {
        case .storage: return "לא ניתן לגשת לאחסון המאובטח. פתח את נעילת המכשיר ונסה שוב."
        case .invalid: return "הקוד אינו עומד בדרישות."
        case .mismatch: return "הקוד שהוזן שגוי."
        case .changed: return "האפליקציה ננעלה. נסה שוב לאחר פתיחתה."
        }
    }
}

@MainActor
final class AppLockStore: ObservableObject {
    static let shared = AppLockStore()
    @Published private(set) var enabled = false
    @Published private(set) var locked = true
    @Published private(set) var timeout: AppLockTimeout = .immediate
    @Published private(set) var mode: AppLockMode = .pin
    @Published private(set) var busy = false
    @Published private(set) var storageError: String?
    @Published private(set) var retryAfter = Date.distantPast
    private var record: AppLockRecord?
    @Published private(set) var foreground = false
    private var gracePeriod = AppLockGracePeriod()
    private var active = false
    private var epoch = 0
    private let rounds: UInt32 = 600_000
    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: (Bundle.main.bundleIdentifier ?? "com.watgbridge.ios") + ".app-lock.v1",
         kSecAttrAccount as String: "credential"]
    }
    private init() { reload() }

    private func reload() {
        do {
            var request = query
            request[kSecReturnData as String] = true
            request[kSecMatchLimit as String] = kSecMatchLimitOne
            var result: CFTypeRef?
            let status = SecItemCopyMatching(request as CFDictionary, &result)
            if status == errSecItemNotFound {
                record = nil; enabled = false; locked = false; storageError = nil
                return
            }
            guard status == errSecSuccess, let data = result as? Data else { throw AppLockFailure.storage }
            let value = try JSONDecoder().decode(AppLockRecord.self, from: data)
            guard value.version == 1, value.salt.count == 32, value.verifier.count == 32,
                  value.rounds == rounds, value.failures >= 0, value.failures <= 20,
                  AppLockTimeout(rawValue: value.timeoutSeconds ?? 0) != nil else { throw AppLockFailure.storage }
            record = value; enabled = true; timeout = AppLockTimeout(rawValue: value.timeoutSeconds ?? 0) ?? .immediate; mode = value.mode; retryAfter = value.retryAfter; storageError = nil
        } catch {
            enabled = true; locked = true; storageError = AppLockFailure.storage.localizedDescription
        }
    }
    private func persist(_ value: AppLockRecord) throws {
        let data = try JSONEncoder().encode(value)
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw AppLockFailure.storage }
        } else if status != errSecSuccess { throw AppLockFailure.storage }
        record = value; timeout = AppLockTimeout(rawValue: value.timeoutSeconds ?? 0) ?? .immediate; mode = value.mode; retryAfter = value.retryAfter; enabled = true; storageError = nil
    }
    func activity(_ isActive: Bool) {
        let wasActive = active
        active = isActive
        foreground = isActive
        if !isActive {
            if wasActive { epoch += 1 }
            if enabled && !locked {
                gracePeriod.leave(at: ContinuousClock.now)
                if timeout == .immediate { locked = true }
            }
        } else {
            if storageError != nil { reload() }
            if enabled && gracePeriod.returnRequiresLock(at: ContinuousClock.now, timeout: timeout) {
                locked = true
            }
        }
    }
    func lockNow() {
        if enabled { epoch += 1; gracePeriod.clear(); locked = true }
    }
    func retryStorage() { reload() }

    private func verify(_ secret: String) async throws {
        guard let original = record, storageError == nil else { throw AppLockFailure.storage }
        guard Date() >= original.retryAfter else {
            throw NSError(domain: "AppLock", code: 1, userInfo: [NSLocalizedDescriptionKey: "יש להמתין עד \(original.retryAfter.formatted(date: .omitted, time: .standard)) לפני ניסיון נוסף."])
        }
        // Bound user input before the expensive KDF, and avoid empty unsafe buffers.
        guard !secret.isEmpty, secret.utf8.count <= 1024 else { throw AppLockFailure.invalid }
        let value = try await Task.detached(priority: .userInitiated) {
            try AppLockCrypto.derive(secret, salt: original.salt, rounds: original.rounds)
        }.value
        var next = original
        if !AppLockCrypto.equal(value, original.verifier) {
            next.failures = min(20, original.failures + 1)
            if next.failures >= 5 {
                let seconds = min(3600.0, 30.0 * pow(2.0, Double(next.failures - 5)))
                next.retryAfter = Date().addingTimeInterval(seconds)
            }
            try persist(next)
            throw AppLockFailure.mismatch
        }
        next.failures = 0; next.retryAfter = .distantPast
        try persist(next)
    }
    func unlock(_ secret: String) async throws {
        guard !busy else { throw AppLockFailure.changed }
        busy = true; defer { busy = false }
        let token = epoch
        try await verify(secret)
        guard active, epoch == token else { throw AppLockFailure.changed }
        locked = false
    }
    func configure(mode newMode: AppLockMode, secret: String, current: String, timeout newTimeout: AppLockTimeout) async throws {
        guard !busy else { throw AppLockFailure.changed }
        guard active, !locked, storageError == nil else { throw AppLockFailure.changed }
        guard newMode.validate(secret), secret.utf8.count <= 1024 else { throw AppLockFailure.invalid }
        busy = true; defer { busy = false }
        let token = epoch
        if enabled { try await verify(current) }
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { throw AppLockFailure.storage }
        let salt = Data(bytes)
        let count = rounds
        let hash = try await Task.detached(priority: .userInitiated) {
            try AppLockCrypto.derive(secret, salt: salt, rounds: count)
        }.value
        guard active, epoch == token, !locked else { throw AppLockFailure.changed }
        try persist(AppLockRecord(version: 1, mode: newMode, salt: salt, verifier: hash,
                                  rounds: rounds, failures: 0, retryAfter: .distantPast, timeoutSeconds: newTimeout.rawValue))
    }
    func setTimeout(_ newTimeout: AppLockTimeout, current: String) async throws {
        guard !busy, enabled, active, !locked, storageError == nil else { throw AppLockFailure.changed }
        busy = true; defer { busy = false }
        let token = epoch
        try await verify(current)
        guard active, epoch == token, !locked, var next = record else { throw AppLockFailure.changed }
        next.timeoutSeconds = newTimeout.rawValue
        try persist(next)
        gracePeriod.clear()
    }
    func disable(current: String) async throws {
        guard !busy else { throw AppLockFailure.changed }
        guard active, !locked else { throw AppLockFailure.changed }
        busy = true; defer { busy = false }
        let token = epoch
        try await verify(current)
        guard active, epoch == token, !locked else { throw AppLockFailure.changed }
        guard SecItemDelete(query as CFDictionary) == errSecSuccess else { throw AppLockFailure.storage }
        record = nil; enabled = false; locked = false; storageError = nil; retryAfter = .distantPast
        timeout = .immediate; gracePeriod.clear()
    }
}
