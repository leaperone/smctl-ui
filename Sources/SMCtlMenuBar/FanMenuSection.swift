import SwiftUI

public struct FanMenuSection: View {
    public var fans: FanSnapshot
    public var perform: (FanCommand) -> Void

    public init(fans: FanSnapshot, perform: @escaping (FanCommand) -> Void) {
        self.fans = fans
        self.perform = perform
    }

    public var body: some View {
        MenuPanel(title: "Fans", systemImage: "fan.fill") {
            Text(fans.profileLine)
                .font(.subheadline.weight(.medium))
                .accessibilityIdentifier("fan-profile")
            if fans.rows.isEmpty {
                Text(fans.emptyLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("fan-empty")
            } else {
                ForEach(fans.rows, id: \.index) { row in
                    Text(row.line)
                        .font(.subheadline)
                        .monospacedDigit()
                        .accessibilityIdentifier("fan-\(row.index)")
                }
                if let daemonMessage = fans.daemonMessage, !daemonMessage.isEmpty {
                    Text(daemonMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let lastWriteError = fans.lastWriteError, !lastWriteError.isEmpty {
                Text(lastWriteError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("fan-write-error")
            }
            Text(FanSnapshot.thermalGuardLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("fan-thermal-guard")

            MenuChoiceRow(choices: FanProfileChoice.allCases.map { choice in
                MenuChoice(
                    id: choice.rawValue,
                    title: choice.menuTitle,
                    accessibilityLabel: choice.menuTitle,
                    accessibilityIdentifier: "fan-profile-\(choice.rawValue)",
                    isSelected: fans.selectedProfile == choice
                ) {
                    perform(choice.command)
                }
            })
            Button("Return to auto") {
                perform(.returnToAuto)
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("fan-return-to-auto")
        }
    }
}
