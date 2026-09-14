import Foundation
#if canImport(SMCtlProtocol)
import SMCtlProtocol
#endif

public enum MenuSnapshot: Equatable, Sendable {
    case idle
    case loading
    case connected(pingLine: String, battery: BatterySnapshot)
    case disconnected(message: String)
}

public struct BatterySnapshot: Equatable, Sendable {
    public var chargePercent: Int?
    public var configuredLimit: String
    public var isCharging: Bool?
    public var pluggedIn: Bool?
    public var chargingControlSupported: Bool
    public var adapterControlSupported: Bool
    public var daemonMessage: String?
    public var lastWriteError: String?

    public init(
        chargePercent: Int?,
        configuredLimit: String,
        isCharging: Bool?,
        pluggedIn: Bool?,
        chargingControlSupported: Bool,
        adapterControlSupported: Bool,
        daemonMessage: String? = nil,
        lastWriteError: String? = nil
    ) {
        self.chargePercent = chargePercent
        self.configuredLimit = configuredLimit
        self.isCharging = isCharging
        self.pluggedIn = pluggedIn
        self.chargingControlSupported = chargingControlSupported
        self.adapterControlSupported = adapterControlSupported
        self.daemonMessage = daemonMessage
        self.lastWriteError = lastWriteError
    }

    public static func from(_ battery: BatteryStatusDTO, lastWriteError: String? = nil) -> BatterySnapshot {
        BatterySnapshot(
            chargePercent: battery.chargePercent,
            configuredLimit: battery.configuredLimit,
            isCharging: battery.isCharging,
            pluggedIn: battery.pluggedIn,
            chargingControlSupported: battery.chargingControlSupported,
            adapterControlSupported: battery.adapterControlSupported,
            daemonMessage: battery.message,
            lastWriteError: lastWriteError
        )
    }

    public var chargeLine: String {
        guard let percent = chargePercent else {
            return "Battery unavailable"
        }
        if isCharging == true {
            return "Battery \(percent)% · charging"
        }
        if pluggedIn == true {
            return "Battery \(percent)% · plugged in"
        }
        return "Battery \(percent)% · on battery"
    }

    public var limitLine: String {
        "Limit \(displayLimit)"
    }

    public var displayLimit: String {
        if selectedMaintain == .stop {
            return "off"
        }
        return configuredLimit
    }

    public var selectedMaintain: MaintainPreset? {
        MaintainPreset.matching(configuredLimit: configuredLimit)
    }

    public func attachingWriteError(_ message: String) -> BatterySnapshot {
        var copy = self
        copy.lastWriteError = message
        return copy
    }
}

extension MenuSnapshot {
    public static func from(ping: PingDTO, battery: BatteryStatusDTO) -> MenuSnapshot {
        guard ping.ok else {
            return .disconnected(message: "Daemon ping returned not ok")
        }
        return .connected(
            pingLine: "smctld ok \(ping.version)",
            battery: BatterySnapshot.from(battery)
        )
    }

    public static func from(error: Error) -> MenuSnapshot {
        let message = errorMessage(error)
        if message.isEmpty {
            return .disconnected(message: "Not connected")
        }
        return .disconnected(message: message)
    }

    public func attachingWriteError(_ message: String) -> MenuSnapshot {
        switch self {
        case .connected(let pingLine, let battery):
            return .connected(pingLine: pingLine, battery: battery.attachingWriteError(message))
        case .idle, .loading, .disconnected:
            return .disconnected(message: message)
        }
    }

    public static func errorMessage(_ error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
