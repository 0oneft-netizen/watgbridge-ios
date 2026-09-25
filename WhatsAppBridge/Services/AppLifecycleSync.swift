import Foundation
import UIKit

final class AppLifecycleSync {
    static let shared = AppLifecycleSync()

    private var observers: [NSObjectProtocol] = []

    private init() {}

    func start() {
        guard observers.isEmpty else {
            return
        }

        let center = NotificationCenter.default

        observers.append(
            center.addObserver(
                forName:
                    UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.resume()
            }
        )

        observers.append(
            center.addObserver(
                forName:
                    UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { _ in
                BackgroundRefreshManager.shared.schedule()
            }
        )
    }

    private func resume() {
        NotificationCenter.default.post(
            name: .backgroundRefreshRequested,
            object: nil
        )

        NotificationCenter.default.post(
            name: .forceRealtimeReconnect,
            object: nil
        )

        BackgroundRefreshManager.shared.schedule()
    }
}
