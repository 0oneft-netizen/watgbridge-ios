import Foundation
import UIKit

actor CustomerAvatarService {
    static let shared = CustomerAvatarService()
    private let cache = NSCache<NSString, UIImage>()
    private var expiry: [String: Date] = [:]
    private var pending: [String: Task<UIImage?, Never>] = [:]
    init() { cache.countLimit = 120; cache.totalCostLimit = 32 * 1024 * 1024 }

    func image(jid: String, accountID: String? = nil) async -> UIImage? {
        let scope = UserWorkspace.id
        guard scope != "signed-out" else { return nil }
        let account = accountID ?? "default"
        let key = scope + "|" + account + "|" + jid
        if let until = expiry[key], until > Date(), let image = cache.object(forKey: key as NSString) { return image }
        if let task = pending[key] {
            let image = await task.value
            return scope == UserWorkspace.id && !Task.isCancelled ? image : nil
        }
        guard let url = APIClient.shared.avatarURL(for: jid, accountID: account),
              let request = await UserAccessStore.shared.avatarRequest(url: url, workspace: scope) else { return nil }
        if let task = pending[key] {
            let image = await task.value
            return scope == UserWorkspace.id && !Task.isCancelled ? image : nil
        }
        // Coalesce concurrent requests and bound network work from long lists.
        guard pending.count < 6 else { return nil }
        let task = Task<UIImage?, Never> {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                      data.count <= 5 * 1024 * 1024, scope == UserWorkspace.id,
                      !Task.isCancelled else { return nil }
                return UIImage(data: data)
            } catch { return nil }
        }
        pending[key] = task
        let image = await task.value
        pending[key] = nil
        guard scope == UserWorkspace.id, !Task.isCancelled else { return nil }
        if let image {
            if expiry.count >= 120 { expiry.removeAll(); cache.removeAllObjects() }
            expiry[key] = Date().addingTimeInterval(300)
            cache.setObject(image, forKey: key as NSString, cost: image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0)
        }
        return image
    }
}
