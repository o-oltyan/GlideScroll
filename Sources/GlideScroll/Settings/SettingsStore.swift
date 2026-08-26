import Foundation
import Observation

enum MainTab: Hashable {
    case scrolling, general, about
}

@MainActor
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    // Transient UI state
    var selectedTab: MainTab = .scrolling

    var smoothScrolling: Bool {
        didSet { defaults.set(smoothScrolling, forKey: Keys.smoothScrolling); pushConfig() }
    }
    var reverseScrolling: Bool {
        didSet { defaults.set(reverseScrolling, forKey: Keys.reverseScrolling); pushConfig() }
    }
    /// 0 = snappy, 1 = floaty. Mapped to the poster's convergence fraction.
    var smoothness: Double {
        didSet { defaults.set(smoothness, forKey: Keys.smoothness); pushConfig() }
    }
    /// Multiplier on each wheel tick, 0.5x – 3x.
    var speed: Double {
        didSet { defaults.set(speed, forKey: Keys.speed); pushConfig() }
    }
    var shiftHorizontal: Bool {
        didSet { defaults.set(shiftHorizontal, forKey: Keys.shiftHorizontal); pushConfig() }
    }
    var optionBypass: Bool {
        didSet { defaults.set(optionBypass, forKey: Keys.optionBypass); pushConfig() }
    }
    var showMenuBarIcon: Bool {
        didSet { defaults.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon) }
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let smoothScrolling = "smoothScrolling"
        static let reverseScrolling = "reverseScrolling"
        static let smoothness = "smoothness"
        static let speed = "speed"
        static let shiftHorizontal = "shiftHorizontal"
        static let optionBypass = "optionBypass"
        static let showMenuBarIcon = "showMenuBarIcon"
    }

    private init() {
        defaults.register(defaults: [
            Keys.smoothScrolling: true,
            Keys.reverseScrolling: false,
            Keys.smoothness: 0.7,
            Keys.speed: 1.0,
            Keys.shiftHorizontal: true,
            Keys.optionBypass: true,
            Keys.showMenuBarIcon: true,
        ])
        smoothScrolling = defaults.bool(forKey: Keys.smoothScrolling)
        reverseScrolling = defaults.bool(forKey: Keys.reverseScrolling)
        smoothness = defaults.double(forKey: Keys.smoothness)
        speed = defaults.double(forKey: Keys.speed)
        shiftHorizontal = defaults.bool(forKey: Keys.shiftHorizontal)
        optionBypass = defaults.bool(forKey: Keys.optionBypass)
        showMenuBarIcon = defaults.bool(forKey: Keys.showMenuBarIcon)
    }

    /// Push the current settings into the engine (call once at launch; the
    /// property observers keep it in sync afterwards).
    func bootstrap() {
        pushConfig()
    }

    private func pushConfig() {
        ScrollEngine.shared.config = EngineConfig(
            smoothEnabled: smoothScrolling,
            reverse: reverseScrolling,
            speed: speed,
            step: 35.0,
            trans: 0.40 - smoothness * 0.32, // smoothness 0…1 → trans 0.40…0.08
            shiftHorizontal: shiftHorizontal,
            optionBypass: optionBypass
        )
    }
}
