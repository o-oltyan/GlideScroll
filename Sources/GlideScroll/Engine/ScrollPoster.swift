import AppKit
import CoreGraphics
import QuartzCore

/// Accumulates wheel ticks into a target and converges toward it once per
/// display frame with an exponential ease-out, emitting continuous
/// (trackpad-like) pixel scroll events.
@MainActor
final class ScrollPoster: NSObject {
    var trans60 = 0.176 // convergence fraction per frame, normalized to 60 Hz

    private var bufferX = 0.0, bufferY = 0.0    // accumulated target
    private var currentX = 0.0, currentY = 0.0  // emitted so far
    private var flags: CGEventFlags = []
    private var displayLink: CADisplayLink?
    private let deadZone = 0.3

    func add(dx: Double, dy: Double, flags: CGEventFlags) {
        self.flags = flags
        if dy != 0 { accumulate(dy, buffer: &bufferY, current: &currentY) }
        if dx != 0 { accumulate(dx, buffer: &bufferX, current: &currentX) }
        startIfNeeded()
    }

    func cancel() {
        reset()
    }

    /// Same-direction ticks pile onto the target; a direction flip hard-resets
    /// so scrolling stops instantly instead of fighting leftover inertia.
    private func accumulate(_ tick: Double, buffer: inout Double, current: inout Double) {
        let remaining = buffer - current
        if remaining != 0 && (tick > 0) != (remaining > 0) {
            buffer = tick
            current = 0
        } else {
            buffer += tick
        }
    }

    private func startIfNeeded() {
        guard displayLink == nil else { return }
        guard let screen = NSScreen.main else { return }
        let link = screen.displayLink(target: self, selector: #selector(stepFrame(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func stepFrame(_ link: CADisplayLink) {
        let frameDuration = link.targetTimestamp - link.timestamp
        let hz = frameDuration > 0 ? 1.0 / frameDuration : 60.0
        // Same feel at any refresh rate: 120 Hz takes smaller steps than 60 Hz.
        let trans = 1.0 - pow(1.0 - trans60, 60.0 / hz)

        let fdy = (bufferY - currentY) * trans
        let fdx = (bufferX - currentX) * trans
        currentY += fdy
        currentX += fdx
        post(dx: fdx, dy: fdy)

        if abs(bufferY - currentY) <= deadZone && abs(bufferX - currentX) <= deadZone {
            reset()
        }
    }

    private func post(dx: Double, dy: Double) {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2,
            wheel1: Int32(dy.rounded()), wheel2: Int32(dx.rounded()), wheel3: 0
        ) else { return }
        event.setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: dy)
        event.setDoubleValueField(.scrollWheelEventPointDeltaAxis2, value: dx)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        event.setIntegerValueField(.eventSourceUserData, value: kGlideScrollMarker)
        event.flags = flags
        event.post(tap: .cgSessionEventTap)
    }

    private func reset() {
        displayLink?.invalidate()
        displayLink = nil
        bufferX = 0; bufferY = 0
        currentX = 0; currentY = 0
    }
}
