import Foundation

enum CacheSizeCalculator {
    private static var mediaDirectory: URL {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(
                "MessageMedia",
                isDirectory: true
            )
    }

    static func bytes() -> Int64 {
        let fm = FileManager.default

        guard let enumerator = fm.enumerator(
            at: mediaDirectory,
            includingPropertiesForKeys: [
                .fileSizeKey,
                .isRegularFileKey
            ]
        ) else {
            return 0
        }

        var total: Int64 = 0

        for case let file as URL in enumerator {
            guard
                let values = try? file.resourceValues(
                    forKeys: [
                        .fileSizeKey,
                        .isRegularFileKey
                    ]
                ),
                values.isRegularFile == true
            else {
                continue
            }

            total += Int64(values.fileSize ?? 0)
        }

        return total
    }

    static func formatted() -> String {
        ByteCountFormatter.string(
            fromByteCount: bytes(),
            countStyle: .file
        )
    }
}
