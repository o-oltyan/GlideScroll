import SwiftUI

@MainActor
struct GeneralSettingsView: View {
    private var settings: SettingsStore { .shared }
    private var loginItem: LaunchAtLogin { .shared }

    // Same @AppStorage key as the MenuBarExtra's isInserted binding — scenes
    // only react to @AppStorage, not to SettingsStore.
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @State private var showHideIconWarning = false

    var body: some View {
        let bindable = Bindable(settings)
        Form {
            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { loginItem.isEnabled },
                    set: { loginItem.setEnabled($0) }
                ))
                if let error = loginItem.lastError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
                if loginItem.requiresApproval {
                    LabeledContent("Login item awaiting approval") {
                        Button("Open Login Items Settings") {
                            loginItem.openLoginItemsSettings()
                        }
                    }
                    .font(.caption)
                }
                if !loginItem.runningFromApplications {
                    Text("Tip: move GlideScroll to the Applications folder so the login item keeps working after updates.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Section {
                Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
                if !showMenuBarIcon {
                    Text("The menu bar icon is hidden. To get back to these settings, open GlideScroll again from Finder, Spotlight, or Raycast.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section("Modifier keys") {
                Toggle("Hold Shift to scroll horizontally", isOn: bindable.shiftHorizontal)
                Toggle("Hold Option to disable smoothing temporarily", isOn: bindable.optionBypass)
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 4)
        .onChange(of: showMenuBarIcon) { _, newValue in
            if !newValue { showHideIconWarning = true }
        }
        .alert("Menu bar icon hidden", isPresented: $showHideIconWarning) {
            Button("OK") {}
        } message: {
            Text("GlideScroll keeps running in the background. To open this window again, launch GlideScroll from Finder, Spotlight, or Raycast.")
        }
        .onAppear {
            loginItem.refresh()
        }
    }
}
