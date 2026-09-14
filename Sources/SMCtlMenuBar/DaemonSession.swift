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

    public func perform(_ command: BatteryCommand) {
        Task {
            let next = await Task.detached { Self.writeThenFetch(command) }.value
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

    nonisolated private static func writeThenFetch(_ command: BatteryCommand) -> MenuSnapshot {
        do {
            try BatteryActions.perform(command)
            return fetchLive()
        } catch {
            return snapshotAfterFailedWrite(error)
        }
    }

    nonisolated private static func snapshotAfterFailedWrite(_ error: Error) -> MenuSnapshot {
        let live = fetchLive()
        let message = MenuSnapshot.errorMessage(error)
        if case .connected = live {
            return live.attachingWriteError(message.isEmpty ? "Write failed" : message)
        }
        return .from(error: error)
    }
}
