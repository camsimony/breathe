import Foundation

/// Shared timing and layout for the calm blur envelope (phase label + countdown).
enum CalmTextTransition {
    /// Full transition: blur out, swap at peak, blur in (seconds).
    static let totalDuration: TimeInterval = 0.8
    static let halfDuration: TimeInterval = totalDuration / 2

    /// Peak blur — opacity hides the swap; keep radius modest for a tight glow.
    static let maxBlurRadius: CGFloat = 7.5

    /// Hold the sharp string before the next blur-out.
    static let holdAfterSharp: TimeInterval = 0.35

    /// Longest phase copy at 20pt semibold rounded (“Exhale” / “Inhale”).
    static let phaseLabelSlotWidth: CGFloat = 108

    /// One line for 20pt semibold rounded; slot roll clip + luminous blob height.
    static let slotLineHeight: CGFloat = 28

    /// Single 48pt light digit — fixed slot avoids horizontal shift.
    static let countdownDigitSlotWidth: CGFloat = 72

    // MARK: - Luminous blob (slot-sized pill + overlapped crossfades)

    /// Old label blurs/fades as the blob rises — same window so the slot never goes empty.
    static let luminousOutgoingCrossfadeDuration: TimeInterval = 0.82
    /// After swap (invisible), blob falls away as the new label sharpens in — blob lasts through the reveal.
    static let luminousIncomingCrossfadeDuration: TimeInterval = 0.86

    /// Last fraction of each phase where the label slowly blurs before the blob handoff.
    static let luminousPreBlurProgressWindow: CGFloat = 0.22
    static let luminousPreBlurMaxRadius: CGFloat = 7.5
    /// Blob opacity at end of that same tail — same smoothstep as blur so intensity stays matched.
    static let luminousPreTailBlobPeak: CGFloat = 0.4

    /// Shape tuner only — mimics the tail-of-phase drift before the blob handoff.
    static let luminousPreviewLeadInDuration: TimeInterval = 0.5

    /// Shared ramp for tail-of-phase: text blur and blob glow use the same `smooth` so they start together.
    static func preTailBlend(phaseProgress p: CGFloat) -> (blur: CGFloat, blobOpacity: CGFloat) {
        let w = luminousPreBlurProgressWindow
        guard p >= 1 - w - 0.0001 else { return (0, 0) }
        let u = (p - (1 - w)) / w
        let t = min(max(u, 0), 1)
        let smooth = t * t * (3 - 2 * t)
        return (smooth * luminousPreBlurMaxRadius, smooth * luminousPreTailBlobPeak)
    }

    static func preBlurRadius(phaseProgress p: CGFloat) -> CGFloat {
        preTailBlend(phaseProgress: p).blur
    }

    /// Inset from the label slot so the pill + blur halo fits without hard clipping.
    static let luminousCapsuleInsetH: CGFloat = 12
    static let luminousCapsuleInsetV: CGFloat = 5
    /// Text blurs this much as it hands off to the slot-sized pill.
    static let luminousTextBlurPeak: CGFloat = 18
    /// Extra blur on the white pill so edges read as a soft horizontal glow.
    static let luminousBlobShapeBlur: CGFloat = 10

    // MARK: - Breath blur (meditative; blur-led inhale / exhale, no blob)

    /// “Inhale”: word softens and blurs until unrecognizable.
    static let breathInDuration: TimeInterval = 1.12
    /// “Exhale”: new word clarifies as blur releases (slightly longer than inhale).
    static let breathOutDuration: TimeInterval = 1.28
    /// Opacity dim and return use the **same** duration so fade-out matches fade-in.
    static let breathOpacityFadeDuration: TimeInterval = 1.24
    /// Default for `UserSettings.breathApproachLeadSeconds` (live value is AppStorage-tunable).
    static let breathApproachLeadSecondsDefault: TimeInterval = 1.0
    /// Shape tuner: pretend each preview “phase” is this long so the lead slider is visible.
    static let breathPreviewFakePhaseDuration: TimeInterval = 3.0
    static let breathBlurPeak: CGFloat = 17
    /// Light dim at peak; blur does most of the unreadability (avoids harsh blackout).
    static let breathOpacityAtPeak: CGFloat = 0.14

    // MARK: - Morph (`.interpolate`)

    /// Stronger blur at peak hides glyph interpolation when word lengths differ.
    static let morphBlurPeak: CGFloat = 14
    static let morphOpacityAtPeak: CGFloat = 0.18
    static let morphPeakDuration: TimeInterval = 0.26
    static let morphSettleDuration: TimeInterval = 0.38

    // MARK: - Slot roll

    static let slotRollDuration: TimeInterval = 0.48
}
