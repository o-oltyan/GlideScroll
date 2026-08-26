import SwiftUI

@main
struct GlideScrollApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // Scene builders don't track @Observable changes, so isInserted must be
    // backed by @AppStorage for the icon to actually appear/disappear live.
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true

    var body: some Scene {
        Window("GlideScroll", id: "main") {
            MainWindowView()
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        .handlesExternalEvents(matching: ["main"])

        MenuBarExtra("GlideScroll", systemImage: "computermouse.fill",
                     isInserted: $showMenuBarIcon) {
            MenuBarView()
        }
    }
}
