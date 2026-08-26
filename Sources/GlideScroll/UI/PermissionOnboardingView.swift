import SwiftUI

@MainActor
struct PermissionOnboardingView: View {
    private var permission: AccessibilityPermission { .shared }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "computermouse.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("Welcome to GlideScroll")
                .font(.title2.bold())
            Text("GlideScroll needs **Accessibility** access to smooth out your mouse wheel. macOS requires this for apps that modify scroll events.\n\nEnable **GlideScroll** in System Settings → Privacy & Security → Accessibility, then come back here — the app picks it up automatically.")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Request Access") {
                    permission.request()
                }
                Button("Open System Settings") {
                    permission.openSystemSettings()
                }
                .buttonStyle(.borderedProminent)
            }
            Label("Waiting for permission…", systemImage: "hourglass")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(28)
    }
}
