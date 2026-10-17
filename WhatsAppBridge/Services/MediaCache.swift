import Foundation
import CryptoKit

actor MediaCache {
    static let shared = MediaCache()

    enum MediaError: Error {
        case invalidResponse
        case emptyFile
    }

    private let fm = FileManager.default
    private let cacheRoot: URL?
    init(directory: URL? = nil) { cacheRoot = directory }
    private var inFlight: [String: Task<URL, Error>] = [:]
    private var activeDownloads = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 4
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 180
        return URLSession(configuration: config)
    }()
    private func acquireDownload() async {
        if activeDownloads < 4 { activeDownloads += 1; return }
        await withCheckedContinuation { waiters.append($0) }
    }
    private func releaseDownload() {
        if !waiters.isEmpty { waiters.removeFirst().resume() } else { activeDownloads -= 1 }
    }

    private var directory: URL {
        if let cacheRoot { return cacheRoot }
        let base = fm.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0]

        return base.appendingPathComponent(
            "MessageMedia",
            isDirectory: true
        )
    }

    func localURL(
        remoteURL: URL,
        messageID: String,
        fileName: String?,
        mimeType: String?,
        chatJID: String? = nil
    ) async throws -> URL {
        try ensureDirectory()

        let ext = preferredExtension(
            fileName: fileName,
            mimeType: mimeType,
            remoteURL: remoteURL
        )

        // The full URL includes account_id, isolating identical WA IDs across accounts.
        let safeID = SHA256.hash(data: Data(remoteURL.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
        var destination = directory
            .appendingPathComponent(safeID)

        if !ext.isEmpty {
            destination =
                destination.appendingPathExtension(ext)
        }

        defer { if let chatJID { trackStorage(remote: remoteURL, local: destination, chat: chatJID, name: fileName ?? "Media") } }

        if fm.fileExists(atPath: destination.path),
           let attrs = try? fm.attributesOfItem(
               atPath: destination.path
           ),
           let size = attrs[.size] as? NSNumber,
           size.int64Value > 0 {
            return destination
        }

        try Task.checkCancellation()
        let key = destination.path
        if let task = inFlight[key] {
            let result = try await task.value
            try Task.checkCancellation()
            return result
        }
        let target = destination
        let task = Task { try await download(remoteURL: remoteURL, destination: target) }
        inFlight[key] = task
        defer { inFlight[key] = nil }
        let result = try await task.value
        try Task.checkCancellation()
        return result
    }

    private func download(remoteURL: URL, destination: URL) async throws -> URL {
        await acquireDownload()
        defer { releaseDownload() }
        let (temporaryURL, response) = try await session.download(from: remoteURL)
        defer { try? fm.removeItem(at: temporaryURL) }
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else { throw MediaError.invalidResponse }
        let attrs = try fm.attributesOfItem(atPath: temporaryURL.path)
        guard let size = attrs[.size] as? NSNumber, size.int64Value > 0 else { throw MediaError.emptyFile }
        // Downloads are shared; finishing one warms the cache for all visible views.
        if fm.fileExists(atPath: destination.path) { return destination }
        try fm.moveItem(at: temporaryURL, to: destination)
        return destination
    }

    private func ensureDirectory() throws {
        if !fm.fileExists(atPath: directory.path) {
            try fm.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }
    }

    private func preferredExtension(
        fileName: String?,
        mimeType: String?,
        remoteURL: URL
    ) -> String {
        if let fileName,
           !fileName.isEmpty {
            let ext =
                (fileName as NSString).pathExtension

            if !ext.isEmpty {
                return normalizedExtension(
                    ext,
                    mimeType: mimeType
                )
            }
        }

        if let mimeType {
            let mime = mimeType.lowercased()

            if mime.contains("jpeg") {
                return "jpg"
            }

            if mime.contains("png") {
                return "png"
            }

            if mime.contains("gif") {
                return "gif"
            }

            if mime.contains("video/mp4") {
                return "mp4"
            }

            if mime.contains("audio/ogg") {
                return "ogg"
            }

            if mime.contains("audio/mp4") ||
               mime.contains("audio/m4a") {
                return "m4a"
            }

            if mime.contains("pdf") {
                return "pdf"
            }
        }

        return normalizedExtension(
            remoteURL.pathExtension,
            mimeType: mimeType
        )
    }

    private func normalizedExtension(
        _ ext: String,
        mimeType: String?
    ) -> String {
        let lower = ext.lowercased()
        guard lower.count <= 12, lower.utf8.allSatisfy({ (48...57).contains($0) || (97...122).contains($0) }) else { return "bin" }

        // WhatsMeow may produce .f4v while the actual
        // response is video/mp4. AVFoundation is happier
        // with an mp4 extension.
        if lower == "f4v",
           mimeType?.lowercased()
               .contains("video/mp4") == true {
            return "mp4"
        }

        if lower == "jpe" {
            return "jpg"
        }

        return lower
    }
}

extension MediaCache {
    private func storageRecords() -> [String: UltraCacheEntry] {
        guard let data = try? Data(contentsOf: directory.appendingPathComponent(".ultra-index.json")), data.count < 20 * 1024 * 1024,
              let decoded = try? JSONDecoder().decode([String: UltraCacheEntry].self, from: data) else { return [:] }
        return decoded.filter { key, value in key == value.file && value.file == (value.file as NSString).lastPathComponent && !key.hasPrefix(".") }
    }
    private func saveStorageRecords(_ records: [String: UltraCacheEntry]) throws {
        try ensureDirectory(); try JSONEncoder().encode(records).write(to: directory.appendingPathComponent(".ultra-index.json"), options: .atomic)
    }
    private func trackStorage(remote: URL, local: URL, chat: String, name: String) {
        guard fm.fileExists(atPath: local.path), let parts = URLComponents(url: remote, resolvingAgainstBaseURL: false),
              let account = parts.queryItems?.first(where: { $0.name == "account_id" })?.value,
              let id = parts.queryItems?.first(where: { $0.name == "id" })?.value else { return }
        let path = remote.pathComponents
        guard path.count >= 4, path[1] == "u", path[2] != "signed-out" else { return }
        var records = storageRecords()
        if let current = records[local.lastPathComponent], current.workspace == path[2], current.chat == chat { return }
        records[local.lastPathComponent] = UltraCacheEntry(workspace: path[2], account: account, chat: chat, message: id, file: local.lastPathComponent, name: name, kept: records[local.lastPathComponent]?.kept ?? false)
        try? saveStorageRecords(records)
    }
    func indexStorage(_ items: [UltraStorageItem], workspace: String, server: URL) throws {
        guard workspace == UserWorkspace.id else { throw CancellationError() }
        try ensureDirectory()
        let files = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey])
        var lookup: [String: URL] = [:]
        for file in files where !file.lastPathComponent.hasPrefix(".") {
            guard let values = try? file.resourceValues(forKeys: [.isRegularFileKey,.isSymbolicLinkKey]), values.isRegularFile == true, values.isSymbolicLink != true else { continue }
            lookup[file.deletingPathExtension().lastPathComponent] = file
        }
        var records = storageRecords()
        for item in items {
            var parts = URLComponents(url: server.appendingPathComponent("u").appendingPathComponent(workspace).appendingPathComponent("media"), resolvingAgainstBaseURL: false)!
            parts.queryItems = [.init(name: "id", value: item.messageID), .init(name: "account_id", value: item.accountID)]
            guard let url = parts.url else { continue }
            let hash = SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
            guard let file = lookup[hash] else { continue }
            records[file.lastPathComponent] = UltraCacheEntry(workspace: workspace, account: item.accountID, chat: item.chatJID, message: item.messageID, file: file.lastPathComponent, name: item.fileName.isEmpty ? item.type : item.fileName, kept: records[file.lastPathComponent]?.kept ?? false)
        }
        try saveStorageRecords(records)
    }
    func storageChats(workspace: String, protectedKeys: Set<String>) -> [UltraCacheChat] {
        guard workspace == UserWorkspace.id else { return [] }
        var grouped: [String: [UltraCacheFile]] = [:]
        for entry in storageRecords().values where entry.workspace == workspace {
            let file = directory.appendingPathComponent(entry.file)
            guard let values = try? file.resourceValues(forKeys: [.fileSizeKey,.isRegularFileKey,.isSymbolicLinkKey]), values.isRegularFile == true, values.isSymbolicLink != true else { continue }
            let item = UltraCacheFile(entry: entry, bytes: Int64(values.fileSize ?? 0), protected: entry.kept || protectedKeys.contains(entry.key))
            grouped[entry.account + "|" + entry.chat, default: []].append(item)
        }
        return grouped.values.compactMap { files in guard let first = files.first else { return nil }; return UltraCacheChat(account: first.entry.account, chat: first.entry.chat, files: files.sorted { $0.bytes > $1.bytes }) }.sorted { $0.bytes > $1.bytes }
    }
    func keepStorageFile(_ id: String, workspace: String, kept: Bool) throws {
        guard UserWorkspace.id == workspace else { throw CancellationError() }
        var records = storageRecords(); guard var entry = records[id], entry.workspace == workspace else { return }; entry.kept = kept; records[id] = entry; try saveStorageRecords(records)
    }
    func cleanStorage(workspace: String, account: String? = nil, chat: String? = nil, protectedKeys: Set<String>, olderThan: Date? = nil) throws -> Int64 {
        guard UserWorkspace.id == workspace else { throw CancellationError() }
        var records = storageRecords(); var removed: Int64 = 0
        for (id, entry) in records where entry.workspace == workspace && (account == nil || entry.account == account) && (chat == nil || entry.chat == chat) {
            guard !entry.kept, !protectedKeys.contains(entry.key), !inFlight.keys.contains(where: { ($0 as NSString).lastPathComponent == entry.file }) else { continue }
            let file = directory.appendingPathComponent(entry.file)
            guard let values = try? file.resourceValues(forKeys: [.fileSizeKey,.isRegularFileKey,.isSymbolicLinkKey,.contentModificationDateKey]), values.isRegularFile == true, values.isSymbolicLink != true else { continue }
            if let cutoff = olderThan, (values.contentModificationDate ?? Date.distantFuture) >= cutoff { continue }
            try fm.removeItem(at: file); removed += Int64(values.fileSize ?? 0); records[id] = nil
        }
        try saveStorageRecords(records); return removed
    }
}
