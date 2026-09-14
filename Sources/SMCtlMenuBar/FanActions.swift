#if canImport(SMCtlClient)
import SMCtlClient
#endif

public enum FanProfileChoice: String, CaseIterable, Equatable, Hashable, Sendable {
    case auto
    case quiet
    case full

    public var wireName: String {
        rawValue
    }

    public var menuTitle: String {
        switch self {
        case .auto:
            return "Auto"
        case .quiet:
            return "Quiet"
        case .full:
            return "Full"
        }
    }

    public static func matching(profile: String) -> FanProfileChoice? {
        let trimmed = profile.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return FanProfileChoice(rawValue: trimmed)
    }

    public var command: FanCommand {
        switch self {
        case .auto:
            return .returnToAuto
        case .quiet, .full:
            return .setProfile(self)
        }
    }
}

public enum FanCommand: Sendable, Equatable {
    case setProfile(FanProfileChoice)
    case returnToAuto
}

public enum FanActions {
    public static func perform(_ command: FanCommand) throws {
        let client = DaemonClient()
        switch command {
        case .returnToAuto:
            try client.setFanAuto(index: nil)
        case .setProfile(let choice):
            try client.setFanProfile(choice.wireName)
        }
    }
}
