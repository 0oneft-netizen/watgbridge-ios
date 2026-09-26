import Foundation

enum MediaStoragePolicy {
    static let cleanupAgeDays =
        30

    static let maximumPreviewBytes:
        Int64 =
            25 * 1024 * 1024

    static func mayCache(
        _ message:
            Message
    ) -> Bool {

        !MessageMediaPolicy
            .isViewOnce(
                message
            )
    }
}
