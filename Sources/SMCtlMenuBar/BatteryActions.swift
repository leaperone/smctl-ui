#if canImport(SMCtlClient)
import SMCtlClient
#endif

/// Charge-limit percentage that can actually be written. Values outside
/// `range` cannot exist after construction.
public struct ChargeLimitCap: Equatable, Hashable, Sendable {
    public static let range: ClosedRange<Int> = 50...100

    public let value: Int

    public init(clamping raw: Int) {
        self.value = min(Self.range.upperBound, max(Self.range.lowerBound, raw))
    }

    public var wireLimit: String {
        String(value)
    }

    public var isFull: Bool {
        value == Self.range.upperBound
    }

    public static func seed(upperBound: Int?, configuredLimit: String) -> ChargeLimitCap {
        if let upperBound {
            return ChargeLimitCap(clamping: upperBound)
        }
        return parse(configuredLimit)
    }

    public static func parse(_ configuredLimit: String) -> ChargeLimitCap {
        let trimmed = configuredLimit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if ["stop", "off", "disabled"].contains(trimmed) {
            return ChargeLimitCap(clamping: range.upperBound)
        }
        if let separator = trimmed.lastIndex(of: "-") {
            let upper = trimmed[trimmed.index(after: separator)...]
            if let parsed = Int(upper) {
                return ChargeLimitCap(clamping: parsed)
            }
        }
        if let parsed = Int(trimmed) {
            return ChargeLimitCap(clamping: parsed)
        }
        return ChargeLimitCap(clamping: range.upperBound)
    }
}

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
    case setCap(Int)
    case setCharging(Bool)

    public var wireLimit: String? {
        switch self {
        case .maintain(let preset):
            return preset.wireLimit
        case .setCap(let raw):
            return ChargeLimitCap(clamping: raw).wireLimit
        case .setCharging:
            return nil
        }
    }
}

public enum BatteryActions {
    public static func perform(_ command: BatteryCommand) throws {
        let client = DaemonClient()
        switch command {
        case .maintain(let preset):
            try client.setChargeLimit(preset.wireLimit)
            if preset == .stop {
                restoreChargingAndAdapter(client)
            }
        case .setCap(let raw):
            let cap = ChargeLimitCap(clamping: raw)
            try client.setChargeLimit(cap.wireLimit)
            if cap.isFull {
                restoreChargingAndAdapter(client)
            }
        case .setCharging(let enabled):
            try client.setChargingEnabled(enabled)
        }
    }

    private static func restoreChargingAndAdapter(_ client: DaemonClient) {
        _ = try? client.setChargingEnabled(true)
        _ = try? client.setAdapterEnabled(true)
    }
}
