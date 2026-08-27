import CoreGraphics

/// Marker written to .eventSourceUserData on every synthetic event so our own
/// tap can recognize and skip them ("GLIDESCR" as big-endian ASCII).
let kGlideScrollMarker: Int64 = 0x474C_4944_4553_4352

extension CGEvent {
    /// True only for discrete mouse-wheel scrolls. Trackpads and Magic Mouse
    /// send continuous events with gesture phases and are passed through.
    var isMouseWheelScroll: Bool {
        getDoubleValueField(.scrollWheelEventScrollPhase) == 0
            && getDoubleValueField(.scrollWheelEventMomentumPhase) == 0
            && getDoubleValueField(.scrollWheelEventScrollCount) == 0
            && getIntegerValueField(.scrollWheelEventIsContinuous) == 0
    }

    /// Best available delta for an axis: pixel-precise point delta, then
    /// fixed-point, then raw line count.
    func usableScrollDelta(vertical: Bool) -> Double {
        let point: CGEventField = vertical ? .scrollWheelEventPointDeltaAxis1 : .scrollWheelEventPointDeltaAxis2
        let fixed: CGEventField = vertical ? .scrollWheelEventFixedPtDeltaAxis1 : .scrollWheelEventFixedPtDeltaAxis2
        let line: CGEventField = vertical ? .scrollWheelEventDeltaAxis1 : .scrollWheelEventDeltaAxis2

        let p = getDoubleValueField(point)
        if p != 0 { return p }
        let f = getDoubleValueField(fixed)
        if f != 0 { return f }
        return getDoubleValueField(line)
    }

    /// In-place direction flip. The three delta representations are coupled:
    /// setting DeltaAxis makes macOS recompute PointDelta (8x) and FixedPtDelta
    /// (1x) from it. So: read everything first, write the line delta first,
    /// then restore the precise fixed/point values (Scroll Reverser's order).
    /// Negate-in-place per field would re-read recomputed values and corrupt
    /// the event (observed: +37 px in, +24 px out — direction unchanged).
    func reverseScrollDeltas() {
        let d1 = getIntegerValueField(.scrollWheelEventDeltaAxis1)
        let p1 = getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
        let f1 = getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let d2 = getIntegerValueField(.scrollWheelEventDeltaAxis2)
        let p2 = getDoubleValueField(.scrollWheelEventPointDeltaAxis2)
        let f2 = getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
        setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -d1)
        setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -f1)
        setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: -p1)
        setIntegerValueField(.scrollWheelEventDeltaAxis2, value: -d2)
        setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -f2)
        setDoubleValueField(.scrollWheelEventPointDeltaAxis2, value: -p2)
    }
}
