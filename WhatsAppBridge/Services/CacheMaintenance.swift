import Foundation

actor CacheMaintenance {
    static let shared =
        CacheMaintenance()

    private let fm =
        FileManager.default

    func cleanup(
        maxAgeDays:
            Int = 30
    ) {
        let base =
            fm.urls(
                for:
                    .cachesDirectory,
                in:
                    .userDomainMask
            )[0]

        let cutoff =
            Date()
                .addingTimeInterval(
                    -Double(
                        maxAgeDays
                    )
                    * 86_400
                )

        guard
            let enumerator =
                fm.enumerator(
                    at: base,
                    includingPropertiesForKeys:
                        [
                            .contentModificationDateKey,
                            .isRegularFileKey
                        ]
                )
        else {
            return
        }

        for case let url
            as URL
            in enumerator {

            guard
                let values =
                    try? url
                        .resourceValues(
                            forKeys:
                                [
                                    .contentModificationDateKey,
                                    .isRegularFileKey
                                ]
                        ),
                values
                    .isRegularFile
                    == true,
                let modified =
                    values
                        .contentModificationDate,
                modified < cutoff
            else {
                continue
            }

            try? fm.removeItem(
                at: url
            )
        }
    }
}
