import AppKit
import SwiftUI

public struct MenuBarRootView: View {
    @Bindable public var session: DaemonSession

    public init(session: DaemonSession) {
        self.session = session
    }

    public var body: some View {
        switch session.snapshot {
        case .idle, .loading:
            Text("Connecting…")
            Text("Waiting for smctld")
        case .connected(let pingLine, let statusLine):
            Text(pingLine)
            Text(statusLine)
        case .disconnected(let message):
            Text("Not connected")
            Text(message)
        }
        Divider()
        Button("Refresh") {
            session.refresh()
        }
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .onAppear {
            session.refresh()
        }
    }
}
