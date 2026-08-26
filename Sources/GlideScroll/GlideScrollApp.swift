import SwiftUI

@main
struct GlideScrollApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var settings = SettingsStore.shared

    var body: some Scene {
        Window("GlideScroll", id: "main") {
            MainWindowView()
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        .handlesExternalEvents(matching: ["main"])

        MenuBarExtra("GlideScroll", systemImage: "computermouse.fill",
                     isInserted: Bindable(settings).showMenuBarIcon) {
            MenuBarView()
        }
    }
}
