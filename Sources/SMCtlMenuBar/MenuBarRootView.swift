import AppKit
import SwiftUI

public struct MenuBarRootView: View {
    public var session: DaemonSession

    public init(session: DaemonSession) {
        self.session = session
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                switch session.snapshot {
                case .idle, .loading:
                    connecting
                case .connected(let pingLine, let battery, let fans):
                    statusHeader(pingLine: pingLine, battery: battery)
                    BatteryMenuSection(battery: battery, perform: session.perform)
                    FanMenuSection(fans: fans, perform: session.perform)
                case .disconnected(let message):
                    disconnected(message)
                }
            }
            .onAppear { session.refresh() }

            footer
        }
        .padding(14)
        .frame(width: 312)
    }

    private var connecting: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Connecting…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private func disconnected(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Not connected", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusHeader(pingLine: String, battery: BatterySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(pingLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("ping-line")
            Text(battery.headline)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .accessibilityLabel(battery.chargeLine)
                .accessibilityIdentifier("battery-charge")
            Text(battery.statusDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("battery-limit")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack {
            Button("Refresh") {
                session.refresh()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .foregroundStyle(.secondary)
        }
    }
}

extension BatterySnapshot {
    var headline: String {
        guard let percent = chargePercent else {
            return "—"
        }
        return "\(percent)%"
    }

    var statusDetail: String {
        var parts: [String] = []
        if chargePercent == nil {
            parts.append("Battery unavailable")
        } else if isCharging == true {
            parts.append("Charging")
        } else if pluggedIn == true {
            parts.append("Plugged in")
        } else {
            parts.append("On battery")
        }
        parts.append(limitLine)
        return parts.joined(separator: " · ")
    }
}
