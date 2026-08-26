import SwiftUI

@MainActor
struct ScrollingSettingsView: View {
    private var settings: SettingsStore { .shared }

    var body: some View {
        let bindable = Bindable(settings)
        Form {
            Section {
                Toggle("Smooth scrolling", isOn: bindable.smoothScrolling)
            }
            Section("Reverse scroll direction") {
                Toggle("Mouse", isOn: bindable.reverseScrolling)
                Toggle("Trackpad", isOn: bindable.reverseTrackpad)
                Text("The two are independent. Magic Mouse scrolls like a trackpad, so the trackpad toggle covers it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                LabeledContent("Smoothness") {
                    Slider(value: bindable.smoothness, in: 0...1) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text("Snappy").font(.caption)
                    } maximumValueLabel: {
                        Text("Floaty").font(.caption)
                    }
                    .frame(width: 240)
                }
                .disabled(!settings.smoothScrolling)
                LabeledContent("Speed") {
                    Slider(value: bindable.speed, in: 0.5...3.0) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text("0.5×").font(.caption)
                    } maximumValueLabel: {
                        Text("3×").font(.caption)
                    }
                    .frame(width: 240)
                }
                .disabled(!settings.smoothScrolling)
            }
            Section("Try it here") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(1...40, id: \.self) { line in
                            Text("Scroll test line \(line)")
                                .foregroundStyle(line % 5 == 0 ? .primary : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                }
                .frame(height: 120)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 4)
    }
}
