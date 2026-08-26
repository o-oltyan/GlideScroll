import AppKit
import ApplicationServices
@preconcurrency import CoreGraphics

struct EngineConfig: Sendable {
    var smoothEnabled = true
    var reverseMouse = false
    var reverseTrackpad = false
    var speed = 1.0          // multiplier on each wheel tick
    var step = 35.0          // minimum px scrolled per wheel notch
    var trans = 0.176        // per-frame convergence fraction at 60 Hz
    var shiftHorizontal = true
    var optionBypass = true
}

private let scrollTapCallback: CGEventTapCallBack = { _, type, event, refcon in
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let engine = Unmanaged<ScrollEngine>.fromOpaque(refcon).takeUnretainedValue()
    // The tap's run-loop source is scheduled on the main run loop, so the
    // callback provably runs on the main actor.
    return MainActor.assumeIsolated {
        engine.handle(type: type, event: event)
    }
}

@MainActor
final class ScrollEngine {
    static let shared = ScrollEngine()

    var config = EngineConfig() {
        didSet { poster.trans60 = config.trans }
    }
    let poster = ScrollPoster()

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isRunning = false

    func start() {
        guard tap == nil, AXIsProcessTrusted() else { return }
        guard let tap = CGEvent.tapCreate(
            tap: .cgAnnotatedSessionEventTap,
            place: .tailAppendEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.scrollWheel.rawValue),
            callback: scrollTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("GlideScroll: failed to create event tap")
            return
        }
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
    }

    func stop() {
        poster.cancel()
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        tap = nil
        runLoopSource = nil
        isRunning = false
    }

    func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Timeouts and user-input disables must re-enable the tap or scrolling dies.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            poster.cancel()
            return Unmanaged.passUnretained(event)
        }
        guard type == .scrollWheel else { return Unmanaged.passUnretained(event) }

        // Our own synthetic events re-enter the tap; the marker check breaks the loop.
        if event.getIntegerValueField(.eventSourceUserData) == kGlideScrollMarker {
            return Unmanaged.passUnretained(event)
        }
        let cfg = config

        guard event.isMouseWheelScroll else {
            // Trackpad (and Magic Mouse) path: pass through, optionally
            // reversed in place. Momentum events carry phases too, so
            // inertial scrolling flips consistently with the gesture.
            if cfg.reverseTrackpad { event.reverseScrollDeltas() }
            return Unmanaged.passUnretained(event)
        }

        if cfg.optionBypass && event.flags.contains(.maskAlternate) {
            if cfg.reverseMouse { event.reverseScrollDeltas() }
            return Unmanaged.passUnretained(event)
        }
        if !cfg.smoothEnabled {
            if cfg.reverseMouse { event.reverseScrollDeltas() }
            return Unmanaged.passUnretained(event)
        }

        var dy = event.usableScrollDelta(vertical: true)
        var dx = event.usableScrollDelta(vertical: false)
        guard dx != 0 || dy != 0 else { return nil }

        // Each notch scrolls at least `step` px; acceleration can exceed it.
        if dy != 0 { dy = (dy > 0 ? 1.0 : -1.0) * max(abs(dy), cfg.step) }
        if dx != 0 { dx = (dx > 0 ? 1.0 : -1.0) * max(abs(dx), cfg.step) }
        dy *= cfg.speed
        dx *= cfg.speed
        if cfg.reverseMouse {
            dy = -dy
            dx = -dx
        }

        var flags = event.flags
        if cfg.shiftHorizontal && flags.contains(.maskShift) && dy != 0 {
            // Route the vertical motion horizontally; strip Shift so target
            // apps don't convert the axis a second time.
            dx = dy
            dy = 0
            flags.remove(.maskShift)
        }

        poster.add(dx: dx, dy: dy, flags: flags)
        return nil // swallow the original discrete event
    }
}
