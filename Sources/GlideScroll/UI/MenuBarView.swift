import AppKit
import SwiftUI

@MainActor
struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    private var settings: SettingsStore { .shared }

    var body: some View {
        let bindable = Bindable(settings)
        Toggle("Smooth Scrolling", isOn: bindable.smoothScrolling)
        Toggle("Reverse Mouse Scrolling", isOn: bindable.reverseScrolling)
        Toggle("Reverse Trackpad Scrolling", isOn: bindable.reverseTrackpad)
        Divider()
        Button("Settings…") {
            settings.selectedTab = .scrolling
            openMainWindow()
        }
        Button("About GlideScroll") {
            settings.selectedTab = .about
            openMainWindow()
        }
        Divider()
        Button("Quit GlideScroll") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
