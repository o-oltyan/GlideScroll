import AppKit
import ApplicationServices
import Observation

@MainActor
@Observable
final class AccessibilityPermission {
    static let shared = AccessibilityPermission()

    private(set) var trusted = AXIsProcessTrusted()
    private var pollTimer: Timer?

    private init() {}

    /// Shows the system prompt (once per TCC state) and starts polling so the
    /// UI flips and the engine starts as soon as the user grants access.
    func request() {
        refresh()
        guard !trusted else { return }
        // Literal value of kAXTrustedCheckOptionPrompt (the extern global is
        // not concurrency-safe to reference under Swift 6).
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        startPolling()
    }

    func startPolling() {
        guard pollTimer == nil, !trusted else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Timer fires on the main run loop.
            MainActor.assumeIsolated {
                AccessibilityPermission.shared.refresh()
            }
        }
    }

    func refresh() {
        let nowTrusted = AXIsProcessTrusted()
        guard nowTrusted != trusted else { return }
        trusted = nowTrusted
        if trusted {
            pollTimer?.invalidate()
            pollTimer = nil
            ScrollEngine.shared.start()
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }
}
