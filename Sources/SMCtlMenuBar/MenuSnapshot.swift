import Foundation
#if canImport(SMCtlProtocol)
import SMCtlProtocol
#endif

public enum MenuSnapshot: Equatable, Sendable {
    case idle
    case loading
    case connected(pingLine: String, statusLine: String)
    case disconnected(message: String)
}

extension MenuSnapshot {
    public static func from(ping: PingDTO, battery: BatteryStatusDTO) -> MenuSnapshot {
        guard ping.ok else {
            return .disconnected(message: "Daemon ping returned not ok")
        }
        return .connected(
            pingLine: "smctld ok \(ping.version)",
            statusLine: batteryStatusLine(battery)
        )
    }

    public static func from(error: Error) -> MenuSnapshot {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        if message.isEmpty {
            return .disconnected(message: "Not connected")
        }
        return .disconnected(message: message)
    }
}

private func batteryStatusLine(_ battery: BatteryStatusDTO) -> String {
    guard let percent = battery.chargePercent else {
        return "Battery unavailable"
    }
    if battery.isCharging == true {
        return "Battery \(percent)% · charging"
    }
    if battery.pluggedIn == true {
        return "Battery \(percent)% · plugged in"
    }
    return "Battery \(percent)% · on battery"
}
