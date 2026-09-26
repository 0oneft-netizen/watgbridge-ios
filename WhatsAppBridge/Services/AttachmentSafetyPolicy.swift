import Foundation

enum AttachmentSafetyPolicy {
    static let warningBytes:
        Int64 =
            50 * 1024 * 1024

    static func fileSize(
        at url: URL
    ) -> Int64? {
        let values =
            try? url.resourceValues(
                forKeys:
                    [.fileSizeKey]
            )

        guard
            let size =
                values?.fileSize
        else {
            return nil
        }

        return Int64(size)
    }

    static func isLarge(
        _ url: URL
    ) -> Bool {
        guard
            let size =
                fileSize(at: url)
        else {
            return false
        }

        return size >
            warningBytes
    }
}
