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
            case .connected(let pingLine, let statusLine):
                Text(pingLine)
                Text(statusLine)
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
