import Foundation

actor MediaSendQueue {
    static let shared =
        MediaSendQueue()

    private var busy = false
    private var waiters:
        [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        if !busy {
            busy = true
            return
        }

        await withCheckedContinuation {
            continuation in

            waiters.append(
                continuation
            )
        }
    }

    func release() {
        if waiters.isEmpty {
            busy = false
            return
        }

        let next =
            waiters.removeFirst()

        next.resume()
    }

    func run<T>(
        _ operation:
            @escaping () async throws -> T
    ) async throws -> T {
        await acquire()

        defer {
            release()
        }

        return try await operation()
    }
}
