import Foundation

extension CacheMaintenance {
    static var shared: CacheMaintenance {
        CacheMaintenance()
    }
}

extension CacheSizeCalculator {
    static var shared: CacheSizeCalculator {
        CacheSizeCalculator()
    }

    static func display(_ bytes: Int64) -> String {
        ByteCountFormatter.string(
            fromByteCount: bytes,
            countStyle: .file
        )
    }

    static func display(_ bytes: Int) -> String {
        ByteCountFormatter.string(
            fromByteCount: Int64(bytes),
            countStyle: .file
        )
    }
}
