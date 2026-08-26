import AppKit
import SwiftUI

@MainActor
struct AboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
    private var copyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
            ?? "© 2026 Octa Oltyan. MIT License."
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text("GlideScroll")
                .font(.title.bold())
            Text("Version \(version) (\(build))")
                .foregroundStyle(.secondary)
            Text("Smooth, trackpad-like scrolling for your mouse.")
                .font(.callout)
            Divider()
                .frame(width: 220)
            Text(copyright)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Released under the MIT License.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Link("github.com/o-oltyan/GlideScroll",
                 destination: URL(string: "https://github.com/o-oltyan/GlideScroll")!)
                .font(.caption)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}
