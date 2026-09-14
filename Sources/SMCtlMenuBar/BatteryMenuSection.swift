import SwiftUI

public struct BatteryMenuSection: View {
    public var battery: BatterySnapshot
    public var perform: (BatteryCommand) -> Void

    public init(battery: BatterySnapshot, perform: @escaping (BatteryCommand) -> Void) {
        self.battery = battery
        self.perform = perform
    }

    public var body: some View {
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

        Divider()
        ForEach(MaintainPreset.allCases, id: \.self) { preset in
            Button(title(for: preset)) {
                perform(.maintain(preset))
            }
            .accessibilityIdentifier("maintain-\(preset.rawValue)")
        }
        if battery.chargingControlSupported {
            Button("Charging on") {
                perform(.setCharging(true))
            }
            .accessibilityIdentifier("charging-on")
            Button("Charging off") {
                perform(.setCharging(false))
            }
            .accessibilityIdentifier("charging-off")
        } else {
            Text("Charging control unsupported")
        }
    }

    private func title(for preset: MaintainPreset) -> String {
        if battery.selectedMaintain == preset {
            return "✓ \(preset.menuTitle)"
        }
        return preset.menuTitle
    }
}
