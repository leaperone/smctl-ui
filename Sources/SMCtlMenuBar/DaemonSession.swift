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
            let next = await Task.detached {
                Self.writeThenFetch(
                    { try BatteryActions.perform(command) },
                    attachError: { $0.attachingBatteryWriteError($1) }
                )
            }.value
            self.snapshot = next
        }
    }

    public func perform(_ command: FanCommand) {
        Task {
            let next = await Task.detached {
                Self.writeThenFetch(
                    { try FanActions.perform(command) },
                    attachError: { $0.attachingFanWriteError($1) }
                )
            }.value
            self.snapshot = next
        }
    }

    // XPC calls block on a semaphore inside DaemonClient. Never run them on the main actor.
    nonisolated private static func fetchLive() -> MenuSnapshot {
        do {
            let client = DaemonClient()
            let ping = try client.ping()
            let battery = try client.getBatteryStatus()
            let fans = try client.getFans()
            return .from(ping: ping, battery: battery, fans: fans)
        } catch {
            return .from(error: error)
        }
    }

    nonisolated private static func writeThenFetch(
        _ write: () throws -> Void,
        attachError: (MenuSnapshot, String) -> MenuSnapshot
    ) -> MenuSnapshot {
        do {
            try write()
            return fetchLive()
        } catch {
            return snapshotAfterFailedWrite(error, attachError: attachError)
        }
    }

    nonisolated private static func snapshotAfterFailedWrite(
        _ error: Error,
        attachError: (MenuSnapshot, String) -> MenuSnapshot
    ) -> MenuSnapshot {
        let live = fetchLive()
        let message = MenuSnapshot.errorMessage(error)
        if case .connected = live {
            return attachError(live, message.isEmpty ? "Write failed" : message)
        }
        return .from(error: error)
    }
}
