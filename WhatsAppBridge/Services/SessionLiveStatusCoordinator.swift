import Foundation

@MainActor
final class SessionLiveStatusCoordinator:
    ObservableObject {

    @Published
    private(set)
    var running = false

    private var task:
        Task<Void, Never>?

    func start() {
        guard
            task == nil
        else {
            return
        }

        running = true

        task =
            Task {
                [weak self] in

                while !Task.isCancelled {
                    if await SessionRefreshPolicy
                        .shared
                        .shouldRefresh(
                            minimumInterval:
                                8
                        ) {

                        await SessionDirectory
                            .shared
                            .refresh()
                    }

                    try? await Task.sleep(
                        for:
                            .seconds(8)
                    )
                }

                self?.running = false
            }
    }

    func stop() {
        task?.cancel()
        task = nil
        running = false
    }

    deinit {
        task?.cancel()
    }
}
