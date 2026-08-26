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

    /// In-place direction flip for the non-smoothed reverse path. All three
    /// delta representations must be negated or apps see inconsistent values.
    func reverseScrollDeltas() {
        let fields: [CGEventField] = [
            .scrollWheelEventDeltaAxis1, .scrollWheelEventPointDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis1,
            .scrollWheelEventDeltaAxis2, .scrollWheelEventPointDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2,
        ]
        for field in fields {
            setDoubleValueField(field, value: -getDoubleValueField(field))
        }
    }
}
