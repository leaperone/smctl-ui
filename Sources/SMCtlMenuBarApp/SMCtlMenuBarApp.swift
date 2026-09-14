#if SWIFT_PACKAGE
import SMCtlMenuBar
#endif
import SwiftUI

@main
struct SMCtlMenuBarApp: App {
    @State private var session = DaemonSession()

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(session: session)
        } label: {
            Text("smctl")
        }
    }
}
