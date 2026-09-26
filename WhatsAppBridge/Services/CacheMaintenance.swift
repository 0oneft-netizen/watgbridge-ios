import Foundation

enum CacheMaintenance {
    private static var mediaDirectory: URL {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(
                "MessageMedia",
                isDirectory: true
            )
    }

    static func removeFilesOlderThan(
        days: Int = 30
    ) {
        let fm = FileManager.default
        let directory = mediaDirectory

        guard let files = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [
                .contentModificationDateKey,
                .isRegularFileKey
            ],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -abs(days),
            to: Date()
        ) ?? Date.distantPast

        for file in files {
            guard
                let values = try? file.resourceValues(
                    forKeys: [
                        .contentModificationDateKey,
                        .isRegularFileKey
                    ]
                ),
                values.isRegularFile == true,
                let modified = values.contentModificationDate,
                modified < cutoff
            else {
                continue
            }

            try? fm.removeItem(at: file)
        }
    }

    static func removeAllMediaCache() {
        let fm = FileManager.default
        let directory = mediaDirectory

        guard fm.fileExists(atPath: directory.path) else {
            return
        }

        try? fm.removeItem(at: directory)
        try? fm.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }
}
