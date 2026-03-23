import SwiftUI

private func warpProgress(_ p: CGFloat, phi: CGFloat) -> CGFloat {
    let a: CGFloat = 0.6
    let freq = 8 * CGFloat.pi
    return p - a * (sin(freq * (p - phi)) + sin(freq * phi)) / freq
}

private let tailLength: CGFloat = 0.40

private extension Animation {
    /// Softer than easeInOut — less “snap” at the ends for luminous crossfades.
    static func luminousOutgoing(duration: TimeInterval) -> Animation {
        .timingCurve(0.2, 0, 0.25, 1, duration: duration)
    }

    static func luminousIncoming(duration: TimeInterval) -> Animation {
        .timingCurve(0.25, 0, 0.2, 1, duration: duration)
    }

    /// Slow gathering — blur builds like an inhale.
    static func breathIn(duration: TimeInterval) -> Animation {
        .timingCurve(0.42, 0, 0.18, 1, duration: duration)
    }

    /// Slow release — blur falls away like an exhale.
    static func breathOut(duration: TimeInterval) -> Animation {
        .timingCurve(0.2, 0, 0.42, 1, duration: duration)
    }
}

struct SquarePathView: View {
    let viewModel: BreathingSessionViewModel
    let squareSize: CGFloat
    private let cr: CGFloat = 10
    @AppStorage("textTransitionStyle") private var transitionStyleRaw: String = "calmEnvelope"
    private var transitionStyle: TextTransitionStyle {
        TextTransitionStyle(rawValue: transitionStyleRaw) ?? .calmEnvelope
    }

    @State private var displayedPhaseLabel: String
    /// For delayed-chrome styles (e.g. calm, luminous, breath blur), updates with the center text swap so outer rails don’t lead the middle.
    @State private var chromePhase: BreathingPhase
    @State private var phaseBlur: CGFloat = 0
    @State private var phaseOpacity: CGFloat = 1
    @State private var phaseTransitionToken: Int = 0
    @State private var morphBlur: CGFloat = 0
    @State private var morphOpacity: CGFloat = 1
    @State private var morphEffectToken: Int = 0

    @State private var reelTop: String
    @State private var reelBottom: String
    @State private var reelOffset: CGFloat = 0
    @State private var slotRollToken: Int = 0

    @State private var luminousTextBlur: CGFloat = 0
    @State private var luminousTextOpacity: CGFloat = 1
    @State private var luminousBlobOpacity: CGFloat = 0
    @State private var luminousLeadBlur: CGFloat = 0
    @State private var luminousLeadBlobOpacity: CGFloat = 0
    @State private var luminousTransitionActive = false

    @State private var breathBlur: CGFloat = 0
    @State private var breathOpacity: CGFloat = 1
    @State private var breathTransitionToken: Int = 0
    @State private var breathInFlight = false
    /// Breath blur only: 1 = active rail at full brightness, 0 = active rail matches subdued rails (dims with center blur-in, brightens after word swap).
    @State private var breathOuterIllumination: CGFloat = 1

    /// Phase for Inhale / Exhale / Hold rails: live `viewModel` except styles that delay chrome until the center transition catches up.
    private var labelPhase: BreathingPhase {
        switch transitionStyle {
        case .calmEnvelope, .luminousBlob, .interpolate, .slotRoll, .breathBlur:
            return chromePhase
        default:
            return viewModel.currentPhase
        }
    }

    init(viewModel: BreathingSessionViewModel, squareSize: CGFloat = 140) {
        self.viewModel = viewModel
        self.squareSize = squareSize
        let label = viewModel.currentPhase.label
        _displayedPhaseLabel = State(initialValue: label)
        _chromePhase = State(initialValue: viewModel.currentPhase)
        _reelTop = State(initialValue: label)
        _reelBottom = State(initialValue: label)
    }

    var body: some View {
        VStack(spacing: 0) {
            phaseLabel("Hold", slot: .holdIn)
                .padding(.bottom, 12)

            HStack(spacing: 0) {
                phaseLabel("Inhale", slot: .inhale)
                    .frame(width: 54, alignment: .trailing)

                Spacer().frame(width: 14)

                ZStack {
                    RoundedRectangle(cornerRadius: cr)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)

                    cometTail(progress: viewModel.overallProgress)

                    Circle()
                        .fill(.white)
                        .frame(width: 12, height: 12)
                        .shadow(color: .white.opacity(0.5), radius: 6)
                        .position(dotPosition(progress: viewModel.overallProgress))

                    VStack(spacing: 3) {
                        phaseText

                        Text(viewModel.timeRemaining)
                            .font(.system(size: 12, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .frame(width: squareSize, height: squareSize)

                Spacer().frame(width: 14)

                phaseLabel("Exhale", slot: .exhale)
                    .frame(width: 54, alignment: .leading)
            }

            phaseLabel("Hold", slot: .holdOut)
                .padding(.top, 12)
        }
        .onAppear {
            let label = viewModel.currentPhase.label
            displayedPhaseLabel = label
            chromePhase = viewModel.currentPhase
            reelTop = label
            reelBottom = label
            phaseBlur = 0
            phaseOpacity = 1
            morphBlur = 0
            morphOpacity = 1
            luminousTextBlur = 0
            luminousTextOpacity = 1
            luminousBlobOpacity = 0
            let blend = CalmTextTransition.preTailBlend(phaseProgress: viewModel.phaseProgress)
            luminousLeadBlur = blend.blur
            luminousLeadBlobOpacity = blend.blobOpacity
            luminousTransitionActive = false
            breathBlur = 0
            breathOpacity = 1
            breathInFlight = false
            breathOuterIllumination = 1
        }
        .onChange(of: transitionStyleRaw) { _, _ in
            breathOuterIllumination = 1
            if TextTransitionStyle(rawValue: transitionStyleRaw) == .breathBlur {
                chromePhase = viewModel.currentPhase
            }
        }
        .onChange(of: viewModel.phaseApproachSignal) { _, _ in
            guard transitionStyle == .breathBlur else { return }
            beginBreathBlurFromApproachSignal()
        }
        .onChange(of: viewModel.phaseProgress) { oldP, newP in
            guard transitionStyle == .luminousBlob, !luminousTransitionActive else { return }
            // Phase wrap resets progress to 0; keep tail values until the blob handoff reads them.
            if newP + 0.02 < oldP { return }
            let blend = CalmTextTransition.preTailBlend(phaseProgress: newP)
            luminousLeadBlur = blend.blur
            luminousLeadBlobOpacity = blend.blobOpacity
        }
        .onChange(of: viewModel.phaseGeneration) { _, _ in
            switch transitionStyle {
            case .calmEnvelope:
                runPhaseBlurEnvelope(to: viewModel.currentPhase.label)
            case .luminousBlob:
                runLuminousBlobEnvelope(to: viewModel.currentPhase.label)
            case .breathBlur:
                guard !breathInFlight else { break }
                runBreathBlurEnvelope()
            case .interpolate:
                runMorphInterpolateEffects()
            case .slotRoll:
                runSlotRoll()
            default:
                break
            }
        }
    }

    // MARK: - Center Phase Text

    @ViewBuilder
    private var phaseText: some View {
        let font = Font.system(size: 20, weight: .semibold, design: .rounded)
        switch transitionStyle {
        case .calmEnvelope:
            Text(displayedPhaseLabel)
                .font(font)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(width: CalmTextTransition.phaseLabelSlotWidth, alignment: .center)
                .blur(radius: phaseBlur)
                .opacity(phaseOpacity)
        case .breathBlur:
            Text(displayedPhaseLabel)
                .font(font)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(width: CalmTextTransition.phaseLabelSlotWidth, alignment: .center)
                .blur(radius: breathBlur)
                .opacity(breathOpacity)
        case .luminousBlob:
            let slotW = CalmTextTransition.phaseLabelSlotWidth
            let slotH = CalmTextTransition.slotLineHeight
            let capW = max(32, slotW - 2 * CalmTextTransition.luminousCapsuleInsetH)
            let capH = max(14, slotH - 2 * CalmTextTransition.luminousCapsuleInsetV)
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.86))
                    .frame(width: capW, height: capH)
                    .blur(radius: CalmTextTransition.luminousBlobShapeBlur)
                    .opacity(luminousTransitionActive ? luminousBlobOpacity : luminousLeadBlobOpacity)
                Text(displayedPhaseLabel)
                    .font(font)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: slotW, height: slotH, alignment: .center)
                    .blur(radius: luminousTransitionActive ? luminousTextBlur : luminousLeadBlur)
                    .opacity(luminousTransitionActive ? luminousTextOpacity : 1)
            }
            .frame(width: slotW, height: slotH)
        case .opacity:
            Text(viewModel.currentPhase.label).font(font).foregroundStyle(.white)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: viewModel.currentPhase)
        case .interpolate:
            Text(viewModel.currentPhase.label)
                .font(font)
                .foregroundStyle(.white)
                .frame(width: CalmTextTransition.phaseLabelSlotWidth, alignment: .center)
                .contentTransition(.interpolate)
                .animation(.easeInOut(duration: CalmTextTransition.morphPeakDuration + CalmTextTransition.morphSettleDuration), value: viewModel.currentPhase)
                .blur(radius: morphBlur)
                .opacity(morphOpacity)
        case .slotRoll:
            VStack(spacing: 0) {
                Text(reelTop)
                    .font(font)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                Text(reelBottom)
                    .font(font)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: CalmTextTransition.phaseLabelSlotWidth, height: CalmTextTransition.slotLineHeight, alignment: .top)
            .clipped()
            .offset(y: reelOffset)
        case .pushUp:
            Text(viewModel.currentPhase.label).font(font).foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: false))
                .animation(.spring(duration: 0.4, bounce: 0.1), value: viewModel.currentPhase)
        case .pushDown:
            Text(viewModel.currentPhase.label).font(font).foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
                .animation(.spring(duration: 0.4, bounce: 0.1), value: viewModel.currentPhase)
        case .blurFade:
            Text(viewModel.currentPhase.label).font(font).foregroundStyle(.white)
                .id(viewModel.currentPhase)
                .transition(AnyTransition.opacity)
                .animation(.easeOut(duration: 0.4), value: viewModel.currentPhase)
        case .scale:
            Text(viewModel.currentPhase.label).font(font).foregroundStyle(.white)
                .id(viewModel.currentPhase)
                .transition(AnyTransition.asymmetric(
                    insertion: AnyTransition.scale(scale: 0.8).combined(with: .opacity),
                    removal: AnyTransition.scale(scale: 1.1).combined(with: .opacity)
                ))
                .animation(.spring(duration: 0.35, bounce: 0.15), value: viewModel.currentPhase)
        }
    }

    private func beginBreathBlurFromApproachSignal() {
        guard transitionStyle == .breathBlur else { return }
        guard !breathInFlight else { return }
        breathTransitionToken += 1
        let token = breathTransitionToken
        breathInFlight = true
        runBreathBlurBody(token: token)
    }

    private func runBreathBlurEnvelope() {
        if breathInFlight { return }
        breathTransitionToken += 1
        let token = breathTransitionToken
        breathInFlight = true
        runBreathBlurBody(token: token)
    }

    private func runBreathBlurBody(token: Int) {
        let inhale = CalmTextTransition.breathInDuration
        let exhale = CalmTextTransition.breathOutDuration
        let opFade = CalmTextTransition.breathOpacityFadeDuration
        let peakBlur = CalmTextTransition.breathBlurPeak
        let peakOpacity = CalmTextTransition.breathOpacityAtPeak

        breathOuterIllumination = 1

        withAnimation(.easeInOut(duration: opFade)) {
            breathOpacity = peakOpacity
        }
        withAnimation(.breathIn(duration: inhale)) {
            breathBlur = peakBlur
            breathOuterIllumination = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + inhale) {
            guard token == self.breathTransitionToken else { return }
            self.displayedPhaseLabel = self.viewModel.currentPhase.label
            self.chromePhase = self.viewModel.currentPhase
            self.breathOuterIllumination = 0
            withAnimation(.easeInOut(duration: opFade)) {
                self.breathOpacity = 1
            }
            withAnimation(.breathOut(duration: exhale)) {
                self.breathBlur = 0
                self.breathOuterIllumination = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + exhale) {
                guard token == self.breathTransitionToken else { return }
                self.breathInFlight = false
            }
        }
    }

    private func runMorphInterpolateEffects() {
        morphEffectToken += 1
        let token = morphEffectToken
        withAnimation(.easeInOut(duration: CalmTextTransition.morphPeakDuration)) {
            morphBlur = CalmTextTransition.morphBlurPeak
            morphOpacity = CalmTextTransition.morphOpacityAtPeak
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + CalmTextTransition.morphPeakDuration) {
            guard token == morphEffectToken else { return }
            withAnimation(.easeInOut(duration: CalmTextTransition.morphSettleDuration)) {
                morphBlur = 0
                morphOpacity = 1
                chromePhase = viewModel.currentPhase
            }
        }
    }

    private func runSlotRoll() {
        slotRollToken += 1
        let token = slotRollToken
        reelTop = reelBottom
        reelBottom = viewModel.currentPhase.label
        reelOffset = 0
        withAnimation(.spring(duration: CalmTextTransition.slotRollDuration, bounce: 0.08)) {
            reelOffset = -CalmTextTransition.slotLineHeight
        }
        let settle = CalmTextTransition.slotRollDuration + 0.03
        DispatchQueue.main.asyncAfter(deadline: .now() + settle) {
            guard token == slotRollToken else { return }
            reelTop = reelBottom
            reelOffset = 0
            chromePhase = viewModel.currentPhase
        }
    }

    private func runPhaseBlurEnvelope(to newLabel: String) {
        phaseTransitionToken += 1
        let token = phaseTransitionToken

        withAnimation(.easeInOut(duration: CalmTextTransition.halfDuration)) {
            phaseBlur = CalmTextTransition.maxBlurRadius
            phaseOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + CalmTextTransition.halfDuration) {
            guard token == phaseTransitionToken else { return }
            withAnimation(.easeInOut(duration: CalmTextTransition.halfDuration)) {
                displayedPhaseLabel = newLabel
                chromePhase = viewModel.currentPhase
                phaseBlur = 0
                phaseOpacity = 1
            }
        }
    }

    private func runLuminousBlobEnvelope(to newLabel: String) {
        phaseTransitionToken += 1
        let token = phaseTransitionToken
        let peakBlur = CalmTextTransition.luminousTextBlurPeak
        let outDur = CalmTextTransition.luminousOutgoingCrossfadeDuration
        let inDur = CalmTextTransition.luminousIncomingCrossfadeDuration

        luminousTransitionActive = true
        let endTail = CalmTextTransition.preTailBlend(phaseProgress: 1)
        let carriedBlur = max(luminousLeadBlur, endTail.blur)
        let carriedBlob = max(luminousLeadBlobOpacity, endTail.blobOpacity)
        luminousTextBlur = carriedBlur
        luminousBlobOpacity = carriedBlob

        // Outgoing: continue from matched tail blur + blob into peak (no step from zero blob).
        withAnimation(.luminousOutgoing(duration: outDur)) {
            luminousTextBlur = peakBlur
            luminousTextOpacity = 0
            luminousBlobOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + outDur) {
            guard token == phaseTransitionToken else { return }
            displayedPhaseLabel = newLabel
            chromePhase = viewModel.currentPhase
            withAnimation(.luminousIncoming(duration: inDur)) {
                luminousBlobOpacity = 0
                luminousTextOpacity = 1
                luminousTextBlur = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + inDur) {
                guard token == phaseTransitionToken else { return }
                luminousTransitionActive = false
                let blend = CalmTextTransition.preTailBlend(phaseProgress: viewModel.phaseProgress)
                luminousLeadBlur = blend.blur
                luminousLeadBlobOpacity = blend.blobOpacity
            }
        }
    }

    // MARK: - Phase Label (outer rails)

    private static let railDimOpacity: CGFloat = 0.15
    private static let railBrightOpacity: CGFloat = 0.7

    private func phaseLabel(_ text: String, slot: BreathingPhase) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(railLabelStyle(for: slot))
            .animation(
                transitionStyle == .breathBlur ? nil : .easeOut(duration: 0.2),
                value: labelPhase == slot
            )
    }

    private func railLabelStyle(for slot: BreathingPhase) -> Color {
        if transitionStyle == .breathBlur {
            if chromePhase == slot {
                let t = Self.railDimOpacity + (Self.railBrightOpacity - Self.railDimOpacity) * breathOuterIllumination
                return .white.opacity(t)
            }
            return .white.opacity(Self.railDimOpacity)
        }
        let isActive = labelPhase == slot
        return .white.opacity(isActive ? Self.railBrightOpacity : Self.railDimOpacity)
    }

    // MARK: - Comet Tail

    private func cometTail(progress: CGFloat) -> some View {
        let s = squareSize
        let center = CGPoint(x: s / 2, y: s / 2)

        let headPos = dotPosition(progress: progress)
        let rawTail = progress - tailLength
        let effectiveTail: CGFloat
        if rawTail >= 0 {
            effectiveTail = rawTail
        } else if viewModel.cyclesCompleted > 0 {
            effectiveTail = rawTail + 1.0
        } else {
            effectiveTail = 0.001
        }
        let tailPos = dotPosition(progress: max(0.001, min(0.999, effectiveTail)))

        let headAngle = atan2(headPos.y - center.y, headPos.x - center.x)
        let tailAngle = atan2(tailPos.y - center.y, tailPos.x - center.x)

        var span = headAngle - tailAngle
        if span < 0 { span += 2 * .pi }
        if span < 0.01 { span = 0.01 }

        let sf = span / (2 * .pi)

        let gradient = AngularGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .white.opacity(0.02), location: sf * 0.5),
                .init(color: .white.opacity(0.10), location: sf * 0.75),
                .init(color: .white.opacity(0.35), location: sf),
                .init(color: .clear, location: min(1.0, sf + 0.001)),
                .init(color: .clear, location: 1.0),
            ],
            center: .center,
            angle: .radians(tailAngle)
        )

        return ZStack {
            RoundedRectangle(cornerRadius: cr)
                .stroke(gradient, lineWidth: 2)
                .blur(radius: 6)
                .opacity(0.5)

            RoundedRectangle(cornerRadius: cr)
                .stroke(gradient, lineWidth: 2)
        }
        .frame(width: s, height: s)
        .allowsHitTesting(false)
    }

    // MARK: - Dot Position

    private func dotPosition(progress: CGFloat) -> CGPoint {
        let s = squareSize
        let r = cr
        let straight = s - 2 * r
        let arcLen = CGFloat.pi * r / 2
        let phaseLen = straight + arcLen

        let phi = (straight + arcLen / 2) / (4 * phaseLen)
        let totalDist = warpProgress(progress, phi: phi) * 4 * phaseLen
        let phase = min(Int(totalDist / phaseLen), 3)
        let dist = totalDist - CGFloat(phase) * phaseLen

        switch phase {
        case 0:
            if dist <= straight {
                return CGPoint(x: 0, y: (s - r) - dist)
            } else {
                let a = CGFloat.pi + ((dist - straight) / arcLen) * (.pi / 2)
                return CGPoint(x: r + r * cos(a), y: r + r * sin(a))
            }
        case 1:
            if dist <= straight {
                return CGPoint(x: r + dist, y: 0)
            } else {
                let a = CGFloat.pi * 1.5 + ((dist - straight) / arcLen) * (.pi / 2)
                return CGPoint(x: (s - r) + r * cos(a), y: r + r * sin(a))
            }
        case 2:
            if dist <= straight {
                return CGPoint(x: s, y: r + dist)
            } else {
                let a = ((dist - straight) / arcLen) * (.pi / 2)
                return CGPoint(x: (s - r) + r * cos(a), y: (s - r) + r * sin(a))
            }
        case 3:
            if dist <= straight {
                return CGPoint(x: (s - r) - dist, y: s)
            } else {
                let a = CGFloat.pi / 2 + ((dist - straight) / arcLen) * (.pi / 2)
                return CGPoint(x: r + r * cos(a), y: (s - r) + r * sin(a))
            }
        default:
            return CGPoint(x: 0, y: s - r)
        }
    }
}

// MARK: - Square Trace Path

struct SquareTracePath: Shape {
    var progress: CGFloat
    var trailStart: CGFloat
    var cornerRadius: CGFloat

    init(progress: CGFloat, trailStart: CGFloat = 0, cornerRadius: CGFloat) {
        self.progress = progress
        self.trailStart = trailStart
        self.cornerRadius = cornerRadius
    }

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let s = rect.width
        let r = cornerRadius
        let straight = s - 2 * r
        let arcLen = CGFloat.pi * r / 2
        let phaseLen = straight + arcLen
        let phi = (straight + arcLen / 2) / (4 * phaseLen)

        let endDist = warpProgress(max(0, min(1, progress)), phi: phi) * 4 * phaseLen
        let startDist = warpProgress(max(0, min(1, trailStart)), phi: phi) * 4 * phaseLen
        guard endDist > startDist + 0.1 else { return path }

        let phaseStarts: [CGPoint] = [
            CGPoint(x: 0, y: s - r),
            CGPoint(x: r, y: 0),
            CGPoint(x: s, y: r),
            CGPoint(x: s - r, y: s),
        ]
        let lineEnds: [CGPoint] = [
            CGPoint(x: 0, y: r),
            CGPoint(x: s - r, y: 0),
            CGPoint(x: s, y: s - r),
            CGPoint(x: r, y: s),
        ]
        let arcCenters: [CGPoint] = [
            CGPoint(x: r, y: r),
            CGPoint(x: s - r, y: r),
            CGPoint(x: s - r, y: s - r),
            CGPoint(x: r, y: s - r),
        ]
        let arcStartDeg: [Double] = [180, 270, 0, 90]

        let startPhase = min(3, Int(startDist / phaseLen))
        let startLocal = startDist - CGFloat(startPhase) * phaseLen

        path.move(to: pointAt(phase: startPhase, localDist: startLocal,
                              s: s, r: r, straight: straight, arcLen: arcLen,
                              phaseStarts: phaseStarts, lineEnds: lineEnds,
                              arcCenters: arcCenters, arcStartDeg: arcStartDeg))

        for i in startPhase..<4 {
            let pStart = CGFloat(i) * phaseLen
            let localStart = max(0, startDist - pStart)
            let localEnd = min(phaseLen, endDist - pStart)
            guard localEnd > localStart + 0.01 else { continue }

            if localStart < straight {
                let drawEnd = min(localEnd, straight)
                let frac = drawEnd / straight
                let from = phaseStarts[i]
                let to = lineEnds[i]
                path.addLine(to: CGPoint(
                    x: from.x + (to.x - from.x) * frac,
                    y: from.y + (to.y - from.y) * frac
                ))
            }

            if localEnd > straight {
                if localStart < straight {
                    path.addLine(to: lineEnds[i])
                }
                let arcLocalStart = max(0, localStart - straight)
                let arcLocalEnd = localEnd - straight
                path.addArc(
                    center: arcCenters[i], radius: r,
                    startAngle: .degrees(arcStartDeg[i] + Double(arcLocalStart / arcLen) * 90),
                    endAngle: .degrees(arcStartDeg[i] + Double(arcLocalEnd / arcLen) * 90),
                    clockwise: false
                )
            }
        }

        return path
    }

    private func pointAt(phase: Int, localDist: CGFloat,
                         s: CGFloat, r: CGFloat, straight: CGFloat, arcLen: CGFloat,
                         phaseStarts: [CGPoint], lineEnds: [CGPoint],
                         arcCenters: [CGPoint], arcStartDeg: [Double]) -> CGPoint {
        if localDist <= straight {
            let frac = localDist / straight
            let from = phaseStarts[phase]
            let to = lineEnds[phase]
            return CGPoint(
                x: from.x + (to.x - from.x) * frac,
                y: from.y + (to.y - from.y) * frac
            )
        } else {
            let angle = (arcStartDeg[phase] + Double((localDist - straight) / arcLen) * 90) * .pi / 180
            return CGPoint(
                x: arcCenters[phase].x + r * CGFloat(cos(angle)),
                y: arcCenters[phase].y + r * CGFloat(sin(angle))
            )
        }
    }
}
