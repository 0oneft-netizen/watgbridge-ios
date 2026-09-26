import Foundation
import Network

@MainActor
final class NetworkMonitor:
    ObservableObject {

    static let shared =
        NetworkMonitor()

    @Published
    private(set)
    var isConnected = true

    @Published
    private(set)
    var isExpensive = false

    @Published
    private(set)
    var interfaceName = "Network"

    private let monitor =
        NWPathMonitor()

    private let queue =
        DispatchQueue(
            label:
                "watgbridge.network.monitor"
        )

    private init() {
        monitor.pathUpdateHandler = {
            [weak self] path in

            Task {
                @MainActor in

                self?.isConnected =
                    path.status
                    ==
                    .satisfied

                self?.isExpensive =
                    path.isExpensive

                if path.usesInterfaceType(
                    .wifi
                ) {
                    self?.interfaceName =
                        "Wi-Fi"
                } else if path
                    .usesInterfaceType(
                        .cellular
                    ) {
                    self?.interfaceName =
                        "Cellular"
                } else {
                    self?.interfaceName =
                        "Network"
                }
            }
        }

        monitor.start(
            queue: queue
        )
    }
}
