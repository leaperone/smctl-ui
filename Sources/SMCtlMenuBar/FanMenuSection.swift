import SwiftUI

public struct FanMenuSection: View {
    public var fans: FanSnapshot
    public var perform: (FanCommand) -> Void

    public init(fans: FanSnapshot, perform: @escaping (FanCommand) -> Void) {
        self.fans = fans
        self.perform = perform
    }

    public var body: some View {
        Text(fans.profileLine)
            .accessibilityIdentifier("fan-profile")
        if fans.rows.isEmpty {
            Text(fans.emptyLine)
                .accessibilityIdentifier("fan-empty")
        } else {
            ForEach(fans.rows, id: \.index) { row in
                Text(row.line)
                    .accessibilityIdentifier("fan-\(row.index)")
            }
            if let daemonMessage = fans.daemonMessage, !daemonMessage.isEmpty {
                Text(daemonMessage)
            }
        }
        if let lastWriteError = fans.lastWriteError, !lastWriteError.isEmpty {
            Text(lastWriteError)
                .accessibilityIdentifier("fan-write-error")
        }
        Text(FanSnapshot.thermalGuardLine)
            .accessibilityIdentifier("fan-thermal-guard")

        Divider()
        ForEach(FanProfileChoice.allCases, id: \.self) { choice in
            Button(title(for: choice)) {
                perform(choice.command)
            }
            .accessibilityIdentifier("fan-profile-\(choice.rawValue)")
        }
        Button("Return to auto") {
            perform(.returnToAuto)
        }
        .accessibilityIdentifier("fan-return-to-auto")
    }

    private func title(for choice: FanProfileChoice) -> String {
        if fans.selectedProfile == choice {
            return "✓ \(choice.menuTitle)"
        }
        return choice.menuTitle
    }
}
