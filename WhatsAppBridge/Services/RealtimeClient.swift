import Foundation

extension Notification.Name {
    static let bridgeRealtimeUpdate = Notification.Name("bridgeRealtimeUpdate")
    static let bridgeIncomingMessage = Notification.Name("bridgeIncomingMessage")
}

struct RealtimeIncomingMessage: Codable {
    let id: Int64
    let chat_jid: String
    let sender_jid: String
    let text: String
    let message_type: String
}

final class RealtimeClient {
    static let shared = RealtimeClient()

    private var updateTask: Task<Void, Never>?
    private var messageTask: Task<Void, Never>?

    private init() {}

    func start() {
        if updateTask == nil {
            updateTask = Task {
                await listenForUpdates()
            }
        }

        if messageTask == nil {
            messageTask = Task {
                await listenForMessages()
            }
        }
    }

    func stop() {
        updateTask?.cancel()
        messageTask?.cancel()

        updateTask = nil
        messageTask = nil
    }

    private func listenForUpdates() async {
        while !Task.isCancelled {
            do {
                let url = URL(
                    string: "https://5jjltkwg.tail256e07.ts.net/events"
                )!

                let (bytes, _) = try await URLSession.shared.bytes(from: url)

                for try await line in bytes.lines {
                    if Task.isCancelled {
                        return
                    }

                    if line.hasPrefix("data:") {
                        let value = line
                            .dropFirst(5)
                            .trimmingCharacters(in: .whitespaces)

                        if value != "ready" {
                            await MainActor.run {
                                NotificationCenter.default.post(
                                    name: .bridgeRealtimeUpdate,
                                    object: nil
                                )
                            }
                        }
                    }
                }
            } catch {
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func listenForMessages() async {
        let decoder = JSONDecoder()

        while !Task.isCancelled {
            do {
                let url = URL(
                    string: "https://5jjltkwg.tail256e07.ts.net/events/messages"
                )!

                let (bytes, _) = try await URLSession.shared.bytes(from: url)

                for try await line in bytes.lines {
                    if Task.isCancelled {
                        return
                    }

                    guard line.hasPrefix("data:") else {
                        continue
                    }

                    let raw = line
                        .dropFirst(5)
                        .trimmingCharacters(in: .whitespaces)

                    guard raw.hasPrefix("{"),
                          let data = raw.data(using: .utf8),
                          let message = try? decoder.decode(
                            RealtimeIncomingMessage.self,
                            from: data
                          )
                    else {
                        continue
                    }

                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .bridgeIncomingMessage,
                            object: message
                        )
                    }
                }
            } catch {
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
