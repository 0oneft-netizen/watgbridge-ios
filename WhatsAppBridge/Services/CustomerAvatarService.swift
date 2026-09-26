import Foundation
import UIKit

actor CustomerAvatarService {
    static let shared = CustomerAvatarService()

    private let cache: NSCache<
        NSString,
        UIImage
    > = {
        let value =
            NSCache<
                NSString,
                UIImage
            >()

        value.countLimit = 120
        value.totalCostLimit =
            32 * 1024 * 1024

        return value
    }()

    func image(
        jid: String
    ) async -> UIImage? {
        let key = jid as NSString

        if let cached =
            cache.object(forKey: key) {
            return cached
        }

        guard let url =
                APIClient.shared.avatarURL(
                    for: jid
                )
        else {
            return nil
        }

        do {
            let (data, response) =
                try await URLSession.shared
                    .data(from: url)

            guard
                let http =
                    response
                    as? HTTPURLResponse,
                (200...299).contains(
                    http.statusCode
                ),
                !data.isEmpty,
                let image =
                    UIImage(data: data)
            else {
                return nil
            }

            cache.setObject(
                image,
                forKey: key
            )

            return image

        } catch {
            return nil
        }
    }
}
