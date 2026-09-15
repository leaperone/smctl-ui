import AppKit
import SwiftUI

public struct MenuBarRootView: View {
    public var session: DaemonSession

    public init(session: DaemonSession) {
        self.session = session
    }

    public var body: some View {
        Group {
            switch session.snapshot {
            case .idle, .loading:
                Text("Connecting…")
            case .connected(let pingLine, let battery, let fans):
                Text(pingLine)
                    .accessibilityIdentifier("ping-line")
                BatteryMenuSection(battery: battery, perform: session.perform)
                Divider()
                FanMenuSection(fans: fans, perform: session.perform)
            case .disconnected(let message):
                Text("Not connected")
                Text(message)
            }
        }
        .onAppear { session.refresh() }

        Divider()

        Button("Refresh") {
            session.refresh()
        }
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
