import AppKit
import SwiftUI

@MainActor
struct MainWindowView: View {
    private var settings: SettingsStore { .shared }
    private var permission: AccessibilityPermission { .shared }

    var body: some View {
        Group {
            if permission.trusted {
                TabView(selection: Bindable(settings).selectedTab) {
                    ScrollingSettingsView()
                        .tabItem { Label("Scrolling", systemImage: "computermouse") }
                        .tag(MainTab.scrolling)
                    GeneralSettingsView()
                        .tabItem { Label("General", systemImage: "gearshape") }
                        .tag(MainTab.general)
                    AboutView()
                        .tabItem { Label("About", systemImage: "info.circle") }
                        .tag(MainTab.about)
                }
            } else {
                PermissionOnboardingView()
            }
        }
        .frame(width: 460)
        .onAppear {
            // Accessory app: show a Dock icon + proper focus while configuring.
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            permission.refresh()
            if !permission.trusted {
                permission.startPolling()
            }
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
