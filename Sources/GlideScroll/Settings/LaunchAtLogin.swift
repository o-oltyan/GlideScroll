import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class LaunchAtLogin {
    static let shared = LaunchAtLogin()

    private(set) var isEnabled: Bool
    private(set) var lastError: String?

    private init() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    var requiresApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    /// SMAppService registers the app at its *current* path, so this is only
    /// reliable when running from /Applications.
    var runningFromApplications: Bool {
        Bundle.main.bundlePath.hasPrefix("/Applications/")
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
