import SwiftUI

public struct BatteryMenuSection: View {
    public var battery: BatterySnapshot
    public var perform: (BatteryCommand) -> Void

    public init(battery: BatterySnapshot, perform: @escaping (BatteryCommand) -> Void) {
        self.battery = battery
        self.perform = perform
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(battery.chargeLine)
                .accessibilityIdentifier("battery-charge")
            Text(battery.limitLine)
                .accessibilityIdentifier("battery-limit")
            if let daemonMessage = battery.daemonMessage, !daemonMessage.isEmpty {
                Text(daemonMessage)
            }
            if let lastWriteError = battery.lastWriteError, !lastWriteError.isEmpty {
                Text(lastWriteError)
                    .accessibilityIdentifier("battery-write-error")
            }

            if battery.chargingControlSupported {
                Divider()
                ChargeLimitSliderRow(seed: battery.sliderCap, perform: perform)
                ForEach(MaintainPreset.allCases, id: \.self) { preset in
                    Button(title(for: preset)) {
                        perform(.maintain(preset))
                    }
                    .accessibilityIdentifier("maintain-\(preset.rawValue)")
                }
                Button("Charging on") {
                    perform(.setCharging(true))
                }
                .accessibilityIdentifier("charging-on")
                Button("Charging off") {
                    perform(.setCharging(false))
                }
                .accessibilityIdentifier("charging-off")
            }
        }
    }

    private func title(for preset: MaintainPreset) -> String {
        if battery.selectedMaintain == preset {
            return "✓ \(preset.menuTitle)"
        }
        return preset.menuTitle
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
        VStack(alignment: .leading, spacing: 4) {
            Text("Charge limit \(Int(draft.rounded()))%")
                .accessibilityIdentifier("charge-limit-label")
            Slider(
                value: $draft,
                in: Double(ChargeLimitCap.range.lowerBound)...Double(ChargeLimitCap.range.upperBound),
                step: 1
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
            .accessibilityValue("\(Int(draft.rounded())) percent")
        }
        .onChange(of: seed) { _, newValue in
            if !isEditing {
                draft = Double(newValue)
            }
        }
    }
}
