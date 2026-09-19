import SwiftUI

public struct BatteryMenuSection: View {
    public var battery: BatterySnapshot
    public var perform: (BatteryCommand) -> Void

    public init(battery: BatterySnapshot, perform: @escaping (BatteryCommand) -> Void) {
        self.battery = battery
        self.perform = perform
    }

    public var body: some View {
        MenuPanel(title: "Charge", systemImage: "battery.100") {
            if let daemonMessage = battery.daemonMessage, !daemonMessage.isEmpty {
                notice(daemonMessage)
            }
            if let lastWriteError = battery.lastWriteError, !lastWriteError.isEmpty {
                notice(lastWriteError, isError: true)
                    .accessibilityIdentifier("battery-write-error")
            }

            if battery.chargingControlSupported {
                ChargeLimitSliderRow(seed: battery.sliderCap, perform: perform)
                Text("Maintain")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MenuChoiceRow(choices: MaintainPreset.allCases.map { preset in
                    MenuChoice(
                        id: preset.rawValue,
                        title: shortTitle(for: preset),
                        accessibilityLabel: preset.menuTitle,
                        accessibilityIdentifier: "maintain-\(preset.rawValue)",
                        isSelected: battery.selectedMaintain == preset
                    ) {
                        perform(.maintain(preset))
                    }
                })
                Text("Charging")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MenuChoiceRow(choices: [
                    MenuChoice(
                        id: "charging-on",
                        title: "On",
                        accessibilityLabel: "Charging on",
                        accessibilityIdentifier: "charging-on",
                        isSelected: false
                    ) {
                        perform(.setCharging(true))
                    },
                    MenuChoice(
                        id: "charging-off",
                        title: "Off",
                        accessibilityLabel: "Charging off",
                        accessibilityIdentifier: "charging-off",
                        isSelected: false
                    ) {
                        perform(.setCharging(false))
                    },
                ])
            }
        }
    }

    private func shortTitle(for preset: MaintainPreset) -> String {
        switch preset {
        case .cap80:
            return "80"
        case .band7080:
            return "70–80"
        case .stop:
            return "Off"
        }
    }

    private func notice(_ text: String, isError: Bool = false) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(isError ? Color.red : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ChargeLimitSliderRow: View {
    var seed: Int
    var perform: (BatteryCommand) -> Void

    @State private var draft: Double
    @State private var isEditing = false

    init(seed: Int, perform: @escaping (BatteryCommand) -> Void) {
        self.seed = seed
        self.perform = perform
        _draft = State(initialValue: Double(seed))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Limit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(shown)%")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .accessibilityIdentifier("charge-limit-label")
            }
            Slider(
                value: $draft,
                in: Double(ChargeLimitCap.range.lowerBound)...Double(ChargeLimitCap.range.upperBound)
            ) { editing in
                isEditing = editing
                guard !editing else { return }
                let cap = ChargeLimitCap(clamping: Int(draft.rounded()))
                draft = Double(cap.value)
                if cap.value != seed {
                    perform(.setCap(cap.value))
                }
            }
            .accessibilityIdentifier("charge-limit-slider")
            .accessibilityValue("\(shown) percent")
            HStack {
                Text("\(ChargeLimitCap.range.lowerBound)")
                Spacer()
                Text("\(ChargeLimitCap.range.upperBound)")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .monospacedDigit()
        }
        .onChange(of: seed) { _, newValue in
            if !isEditing {
                draft = Double(newValue)
            }
        }
    }

    private var shown: Int {
        Int(draft.rounded())
    }
}
