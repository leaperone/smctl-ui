#if canImport(SMCtlClient)
import SMCtlClient
#endif

public enum MaintainPreset: String, CaseIterable, Equatable, Hashable, Sendable {
    case cap80 = "80"
    case band7080 = "70-80"
    case stop = "stop"

    public var wireLimit: String {
        switch self {
        case .cap80:
            return "80"
        case .band7080:
            return "70-80"
        case .stop:
            return "100"
        }
    }

    public var menuTitle: String {
        switch self {
        case .cap80:
            return "Maintain 80"
        case .band7080:
            return "Maintain 70-80"
        case .stop:
            return "Stop maintain"
        }
    }

    public static func matching(configuredLimit: String) -> MaintainPreset? {
        let trimmed = configuredLimit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if ["100", "stop", "off", "disabled"].contains(trimmed) {
            return .stop
        }
        if trimmed == "80" {
            return .cap80
        }
        if trimmed == "70-80" {
            return .band7080
        }
        return nil
    }
}

public enum BatteryCommand: Sendable, Equatable {
    case maintain(MaintainPreset)
    case setCharging(Bool)
}

public enum BatteryActions {
    public static func perform(_ command: BatteryCommand) throws {
        let client = DaemonClient()
        switch command {
        case .maintain(let preset):
            try client.setChargeLimit(preset.wireLimit)
        case .setCharging(let enabled):
            try client.setChargingEnabled(enabled)
        }
    }
}
