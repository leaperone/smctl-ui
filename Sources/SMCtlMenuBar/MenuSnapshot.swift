import Foundation
#if canImport(SMCtlProtocol)
import SMCtlProtocol
#endif

public enum MenuSnapshot: Equatable, Sendable {
    case idle
    case loading
    case connected(pingLine: String, battery: BatterySnapshot, fans: FanSnapshot)
    case disconnected(message: String)
}

public struct BatterySnapshot: Equatable, Sendable {
    public var chargePercent: Int?
    public var configuredLimit: String
    public var upperBound: Int?
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
        lastWriteError: String? = nil,
        upperBound: Int? = nil
    ) {
        self.chargePercent = chargePercent
        self.configuredLimit = configuredLimit
        self.upperBound = upperBound
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
            lastWriteError: lastWriteError,
            upperBound: battery.upperBound
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

    public var sliderCap: Int {
        ChargeLimitCap.seed(upperBound: upperBound, configuredLimit: configuredLimit).value
    }

    public func attachingWriteError(_ message: String) -> BatterySnapshot {
        var copy = self
        copy.lastWriteError = message
        return copy
    }
}

public struct FanRPMRow: Equatable, Sendable {
    public var index: Int
    public var actualRPM: Double?
    public var targetRPM: Double?
    public var mode: String

    public init(index: Int, actualRPM: Double?, targetRPM: Double?, mode: String) {
        self.index = index
        self.actualRPM = actualRPM
        self.targetRPM = targetRPM
        self.mode = mode
    }

    public var line: String {
        "Fan \(index) · \(Self.formatRPM(actualRPM))"
    }

    public static func formatRPM(_ value: Double?) -> String {
        guard let value else {
            return "—"
        }
        return "\(String(format: "%.0f", value)) RPM"
    }
}

public struct FanSnapshot: Equatable, Sendable {
    public var profile: String
    public var rows: [FanRPMRow]
    public var daemonMessage: String?
    public var lastWriteError: String?

    public static let thermalGuardLine = "Thermal guard remains active."

    public init(
        profile: String,
        rows: [FanRPMRow],
        daemonMessage: String? = nil,
        lastWriteError: String? = nil
    ) {
        self.profile = profile
        self.rows = rows
        self.daemonMessage = daemonMessage
        self.lastWriteError = lastWriteError
    }

    public static func from(_ fans: FansStatusDTO, lastWriteError: String? = nil) -> FanSnapshot {
        FanSnapshot(
            profile: fans.profile,
            rows: fans.fans.map { fan in
                FanRPMRow(
                    index: fan.index,
                    actualRPM: fan.actualRPM,
                    targetRPM: fan.targetRPM,
                    mode: fan.mode
                )
            },
            daemonMessage: fans.message,
            lastWriteError: lastWriteError
        )
    }

    public var profileLine: String {
        "Profile \(profile)"
    }

    public var emptyLine: String {
        if let daemonMessage, !daemonMessage.isEmpty {
            return daemonMessage
        }
        return "No fans were reported by SMC."
    }

    public var selectedProfile: FanProfileChoice? {
        FanProfileChoice.matching(profile: profile)
    }

    public func attachingWriteError(_ message: String) -> FanSnapshot {
        var copy = self
        copy.lastWriteError = message
        return copy
    }
}

extension MenuSnapshot {
    public static func from(ping: PingDTO, battery: BatteryStatusDTO, fans: FansStatusDTO) -> MenuSnapshot {
        guard ping.ok else {
            return .disconnected(message: "Daemon ping returned not ok")
        }
        return .connected(
            pingLine: "smctld ok \(ping.version)",
            battery: BatterySnapshot.from(battery),
            fans: FanSnapshot.from(fans)
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
        attachingBatteryWriteError(message)
    }

    public func attachingBatteryWriteError(_ message: String) -> MenuSnapshot {
        switch self {
        case .connected(let pingLine, let battery, let fans):
            return .connected(pingLine: pingLine, battery: battery.attachingWriteError(message), fans: fans)
        case .idle, .loading, .disconnected:
            return .disconnected(message: message)
        }
    }

    public func attachingFanWriteError(_ message: String) -> MenuSnapshot {
        switch self {
        case .connected(let pingLine, let battery, let fans):
            return .connected(pingLine: pingLine, battery: battery, fans: fans.attachingWriteError(message))
        case .idle, .loading, .disconnected:
            return .disconnected(message: message)
        }
    }

    public static func errorMessage(_ error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
