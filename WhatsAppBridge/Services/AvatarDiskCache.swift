import Foundation
import UIKit
import CryptoKit

actor AvatarDiskCache {
    static let shared =
        AvatarDiskCache()

    private let directory:
        URL

    init() {
        let base =
            FileManager.default.urls(
                for: .cachesDirectory,
                in: .userDomainMask
            )[0]

        directory =
            base.appendingPathComponent(
                "AvatarCache",
                isDirectory: true
            )

        try? FileManager.default
            .createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
    }

    private func normalizedAccountID(
        _ accountID: String?
    ) -> String {

        let value =
            accountID?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            ?? ""

        return value.isEmpty
            ? "default"
            : value
    }

    private func cacheKey(
        accountID: String?,
        jid: String
    ) -> String {

        UserWorkspace.id + "|" + normalizedAccountID(accountID)
        + "|"
        + jid
    }

    private func fileURL(
        accountID: String?,
        jid: String
    ) -> URL {

        let key =
            cacheKey(
                accountID: accountID,
                jid: jid
            )

        let digest =
            SHA256.hash(
                data: Data(key.utf8)
            )
            .map {
                String(
                    format: "%02x",
                    $0
                )
            }
            .joined()

        return directory
            .appendingPathComponent(
                digest + ".jpg"
            )
    }

    func image(
        accountID: String?,
        jid: String
    ) -> UIImage? {

        let url =
            fileURL(
                accountID: accountID,
                jid: jid
            )

        guard
            let data =
                try? Data(
                    contentsOf: url
                )
        else {
            return nil
        }

        return UIImage(
            data: data
        )
    }

    func store(
        _ image: UIImage,
        accountID: String?,
        jid: String
    ) {
        guard
            let data =
                image.jpegData(
                    compressionQuality: 0.88
                )
        else {
            return
        }

        let url =
            fileURL(
                accountID: accountID,
                jid: jid
            )

        try? data.write(
            to: url,
            options: .atomic
        )
    }

    // Compatibility only.
    // New multi-account callers should always pass accountID.
    func image(
        jid: String
    ) -> UIImage? {
        image(
            accountID: "default",
            jid: jid
        )
    }

    // Compatibility only.
    func store(
        _ image: UIImage,
        jid: String
    ) {
        store(
            image,
            accountID: "default",
            jid: jid
        )
    }

    func removeAll() {
        try? FileManager.default
            .removeItem(
                at: directory
            )

        try? FileManager.default
            .createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
    }


    static func accountAwareKey(
        accountID: String?,
        jid: String
    ) -> String {
        let account = (accountID ?? "default")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let route = account.isEmpty ? "default" : account

        let raw = UserWorkspace.id + "|" + route + "|" + jid

        return raw
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "@", with: "_")
    }
}
