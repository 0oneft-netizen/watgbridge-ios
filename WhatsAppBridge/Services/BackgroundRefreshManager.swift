import Foundation
import BackgroundTasks
import UIKit

final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()

    static let refreshIdentifier =
        "com.watgbridge.ios.refresh"

    private init() {}

    func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshIdentifier,
            using: nil
        ) { task in
            guard let refreshTask =
                    task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            self.handle(refreshTask)
        }
    }

    func schedule() {
        BGTaskScheduler.shared.cancel(
            taskRequestWithIdentifier:
                Self.refreshIdentifier
        )

        let request = BGAppRefreshTaskRequest(
            identifier: Self.refreshIdentifier
        )

        request.earliestBeginDate =
            Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print(
                "[BG] schedule failed:",
                error.localizedDescription
            )
        }
    }

    private func handle(
        _ task: BGAppRefreshTask
    ) {
        schedule()

        var finished = false

        task.expirationHandler = {
            finished = true
        }

        Task {
            guard !finished else {
                task.setTaskCompleted(success: false)
                return
            }

            NotificationCenter.default.post(
                name: .backgroundRefreshRequested,
                object: nil
            )

            try? await Task.sleep(
                nanoseconds: 8_000_000_000
            )

            task.setTaskCompleted(
                success: !finished
            )
        }
    }
}

extension Notification.Name {
    static let backgroundRefreshRequested =
        Notification.Name(
            "backgroundRefreshRequested"
        )

    static let forceRealtimeReconnect =
        Notification.Name(
            "forceRealtimeReconnect"
        )
}
