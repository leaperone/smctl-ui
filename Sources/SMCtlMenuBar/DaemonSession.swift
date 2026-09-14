import Foundation
#if canImport(SMCtlClient)
import SMCtlClient
#endif
#if canImport(SMCtlProtocol)
import SMCtlProtocol
#endif

@MainActor
@Observable
public final class DaemonSession {
    public private(set) var snapshot: MenuSnapshot = .idle

    public init() {
        Task { refresh() }
    }

    public func refresh() {
        snapshot = .loading
        Task {
            let next = await Task.detached { Self.fetchLive() }.value
            self.snapshot = next
        }
    }

    // XPC calls block on a semaphore inside DaemonClient. Never run them on the main actor.
    nonisolated private static func fetchLive() -> MenuSnapshot {
        do {
            let client = DaemonClient()
            let ping = try client.ping()
            let battery = try client.getBatteryStatus()
            return .from(ping: ping, battery: battery)
        } catch {
            return .from(error: error)
        }
    }
}
