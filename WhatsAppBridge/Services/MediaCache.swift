import Foundation
import CryptoKit

actor MediaCache {
    static let shared = MediaCache()

    enum MediaError: Error {
        case invalidResponse
        case emptyFile
    }

    private let fm = FileManager.default
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
        mimeType: String?
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
