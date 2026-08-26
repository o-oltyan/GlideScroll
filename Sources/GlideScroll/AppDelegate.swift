import AppKit
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        SettingsStore.shared.bootstrap()
        if AXIsProcessTrusted() {
            ScrollEngine.shared.start()
        }
        if !Self.isLoginItemLaunch() {
            openMainWindow()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openMainWindow()
        }
        return true
    }

    /// The main window scene handles external events matching "main", so opening
    /// our own URL is the reliable way to present it from AppDelegate context.
    func openMainWindow() {
        if let url = URL(string: "glidescroll://main") {
            NSWorkspace.shared.open(url)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Login-item launches carry keyAELaunchedAsLogInItem ('lgit') in the 'oapp'
    /// open event's property data. Numeric literals to avoid Carbon imports.
    private static func isLoginItemLaunch() -> Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent else { return false }
        let kAEOpenApp: AEEventID = 0x6F61_7070      // 'oapp'
        let keyPropData: AEKeyword = 0x7072_6474     // 'prdt'
        let launchedAsLoginItem: OSType = 0x6C67_6974 // 'lgit'
        return event.eventID == kAEOpenApp
            && event.paramDescriptor(forKeyword: keyPropData)?.enumCodeValue == launchedAsLoginItem
    }
}
