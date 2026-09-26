import Foundation

actor CacheSizeCalculator {
    static let shared =
        CacheSizeCalculator()

    func bytes() -> Int64 {
        let fm =
            FileManager.default

        let base =
            fm.urls(
                for:
                    .cachesDirectory,
                in:
                    .userDomainMask
            )[0]

        guard
            let enumerator =
                fm.enumerator(
                    at: base,
                    includingPropertiesForKeys:
                        [.fileSizeKey]
                )
        else {
            return 0
        }

        var total:
            Int64 = 0

        for case let url
            as URL
            in enumerator {

            if let size =
                try? url
                    .resourceValues(
                        forKeys:
                            [.fileSizeKey]
                    )
                    .fileSize {

                total +=
                    Int64(size)
            }
        }

        return total
    }

    static func display(
        _ bytes: Int64
    ) -> String {
        ByteCountFormatter
            .string(
                fromByteCount:
                    bytes,
                countStyle:
                    .file
            )
    }
}
