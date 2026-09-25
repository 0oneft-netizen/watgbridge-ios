import Foundation

actor MediaCache {
    static let shared = MediaCache()

    enum MediaError: Error {
        case invalidResponse
        case emptyFile
    }

    private let fm = FileManager.default

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

        let safeID = messageID.replacingOccurrences(
            of: "/",
            with: "_"
        )

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

        let (temporaryURL, response) =
            try await URLSession.shared.download(
                from: remoteURL
            )

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode)
        else {
            throw MediaError.invalidResponse
        }

        let attrs = try fm.attributesOfItem(
            atPath: temporaryURL.path
        )

        guard let size = attrs[.size] as? NSNumber,
              size.int64Value > 0
        else {
            throw MediaError.emptyFile
        }

        if fm.fileExists(atPath: destination.path) {
            try fm.removeItem(at: destination)
        }

        try fm.moveItem(
            at: temporaryURL,
            to: destination
        )

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
