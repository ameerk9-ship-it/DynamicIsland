import Foundation
import Network
import CoreWLAN

final class NetworkManager {

    var onUpdate: ((_ connected: Bool, _ name: String) -> Void)?

    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "com.amir.dynamicisland.network")
    private var lastConnected: Bool?

    func start() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            guard connected != self.lastConnected else { return }
            self.lastConnected = connected

            let name = connected ? (CWWiFiClient.shared().interface()?.ssid() ?? "شبكة متصلة") : "بدون اتصال"
            DispatchQueue.main.async {
                self.onUpdate?(connected, name)
            }
        }
        monitor.start(queue: queue)
        self.monitor = monitor
    }

    func stop() {
        monitor?.cancel()
        monitor = nil
    }
}
