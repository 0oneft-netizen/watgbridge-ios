import Foundation

extension Notification.Name {
    static let bridgeRealtimeUpdate =
        Notification.Name(
            "bridgeRealtimeUpdate"
        )
}

final class RealtimeClient {
    static let shared =
        RealtimeClient()

    private var task:
        Task<Void, Never>?

    private init() {}

    func start() {
        if task != nil {
            return
        }

        task = Task {
            await listenForever()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func listenForever() async {
        while !Task.isCancelled {
            do {
                guard let url = URL(
                    string:
                        "https://5jjltkwg.tail256e07.ts.net/events"
                ) else {
                    return
                }

                var request =
                    URLRequest(url: url)

                request.timeoutInterval =
                    60 * 60

                request.setValue(
                    "text/event-stream",
                    forHTTPHeaderField:
                        "Accept"
                )

                let (bytes, response) =
                    try await URLSession
                        .shared
                        .bytes(
                            for: request
                        )

                guard
                    let http =
                        response
                        as? HTTPURLResponse,
                    (200...299).contains(
                        http.statusCode
                    )
                else {
                    throw URLError(
                        .badServerResponse
                    )
                }

                for try await line
                    in bytes.lines {

                    if Task.isCancelled {
                        return
                    }

                    guard
                        line.hasPrefix(
                            "data:"
                        )
                    else {
                        continue
                    }

                    let value =
                        line
                        .dropFirst(5)
                        .trimmingCharacters(
                            in:
                                .whitespaces
                        )

                    if value == "ready" {
                        continue
                    }

                    await MainActor.run {
                        NotificationCenter
                            .default
                            .post(
                                name:
                                    .bridgeRealtimeUpdate,
                                object: nil
                            )
                    }
                }

            } catch {
                if Task.isCancelled {
                    return
                }

                try? await Task.sleep(
                    for: .seconds(1)
                )
            }
        }
    }
}
