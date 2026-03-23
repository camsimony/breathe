import SwiftUI

private extension Animation {
    static func luminousOutgoing(duration: TimeInterval) -> Animation {
        .timingCurve(0.2, 0, 0.25, 1, duration: duration)
    }

    static func luminousIncoming(duration: TimeInterval) -> Animation {
        .timingCurve(0.25, 0, 0.2, 1, duration: duration)
    }

    static func breathIn(duration: TimeInterval) -> Animation {
        .timingCurve(0.42, 0, 0.18, 1, duration: duration)
    }

    static func breathOut(duration: TimeInterval) -> Animation {
        .timingCurve(0.2, 0, 0.42, 1, duration: duration)
    }
}

struct ShapeTunerView: View {
    @State private var shapeWidth: CGFloat = 290
    @State private var shapeHeight: CGFloat = 240
    @State private var topRadius: CGFloat = 10
    @State private var bottomRadius: CGFloat = 30
    @State private var straightMult: CGFloat = 1.0
    @State private var curveMult: CGFloat = 2.3
    @State private var overshootPct: CGFloat = 0.61
    @State private var curveBlend: CGFloat = 0.55

    @AppStorage("textTransitionStyle") private var selectedTransitionRaw: String = "calmEnvelope"
    @AppStorage("breathApproachLeadSeconds") private var breathApproachLeadSeconds = 1.0
    private var selectedTransition: TextTransitionStyle {
        get { TextTransitionStyle(rawValue: selectedTransitionRaw) ?? .calmEnvelope }
    }
    @State private var previewPhaseIndex: Int = 0
    @State private var previewTimer: Timer?
    @State private var morphBlur: CGFloat = 0
    @State private var morphPreviewOpacity: CGFloat = 1

    @State private var reelPreviewTop: String = "Inhale"
    @State private var reelPreviewBottom: String = "Inhale"
    @State private var reelPreviewOffset: CGFloat = 0

    @State private var calmPreviewDisplayed: String = "Inhale"
    @State private var calmPreviewBlur: CGFloat = 0
    @State private var calmPreviewOpacity: CGFloat = 1
    @State private var calmPreviewToken: Int = 0

    @State private var luminousPreviewTextBlur: CGFloat = 0
    @State private var luminousPreviewTextOpacity: CGFloat = 1
    @State private var luminousPreviewBlobOpacity: CGFloat = 0
    @State private var luminousPreviewLeadBlur: CGFloat = 0
    @State private var luminousPreviewLeadBlobOpacity: CGFloat = 0
    @State private var luminousPreviewTransitionActive = false
    @State private var luminousPreviewToken: Int = 0

    @State private var breathPreviewBlur: CGFloat = 0
    @State private var breathPreviewOpacity: CGFloat = 1
    @State private var breathPreviewToken: Int = 0
    @State private var breathPreviewLoopToken: Int = 0

    private let phaseLabels = ["Inhale", "Hold", "Exhale", "Hold"]

    var body: some View {
        HStack(spacing: 0) {
            preview
            Divider()
            controls
                .frame(width: 260)
        }
        .frame(width: 700, height: 560)
    }

    // MARK: - Preview

    private var preview: some View {
        ZStack {
            Color(white: 0.15)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 30)

                ZStack(alignment: .top) {
                    Color.clear

                    Color.black
                        .frame(width: shapeWidth, height: shapeHeight)
                        .clipShape(
                            TunableNotchShape(
                                shapeWidth: shapeWidth,
                                shapeHeight: shapeHeight,
                                topCornerRadius: topRadius,
                                bottomCornerRadius: bottomRadius,
                                straightMult: straightMult,
                                curveMult: curveMult,
                                overshootPct: overshootPct,
                                curveBlend: curveBlend
                            )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
                }
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Shape Tuner")
                    .font(.headline)

                Group {
                    sliderRow("Width", value: $shapeWidth, range: 200...400, display: "%.0f")
                    sliderRow("Height", value: $shapeHeight, range: 150...350, display: "%.0f")
                }

                Divider()

                Group {
                    sliderRow("Ear Width (topR)", value: $topRadius, range: 0...40, display: "%.0f")
                    sliderRow("Bottom Radius", value: $bottomRadius, range: 0...40, display: "%.0f")
                }

                Divider()

                Group {
                    sliderRow("Straight Drop", value: $straightMult, range: 0...2, display: "%.2f")
                    sliderRow("Curve Height", value: $curveMult, range: 0.5...4, display: "%.2f")
                    sliderRow("Overshoot %", value: $overshootPct, range: 0...1, display: "%.0f%%") { $0 * 100 }
                    sliderRow("Curve Blend", value: $curveBlend, range: 0.2...0.8, display: "%.2f")
                }

                Divider()

                Text("Curve Blend: lower = bends inward sooner (softer bezel edge)")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)

                Divider()

                textTransitionSection

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Code Values").font(.caption).foregroundStyle(.secondary)
                    codeBlock
                }

                Button("Copy to Clipboard") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(codeString, forType: .string)
                }
                .controlSize(.small)
            }
            .padding()
        }
    }

    // MARK: - Text Transition

    private var textTransitionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Text Transition")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Style", selection: $selectedTransitionRaw) {
                ForEach(TextTransitionStyle.allCases) { style in
                    Text(style.label).tag(style.rawValue)
                }
            }
            .pickerStyle(.radioGroup)

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black)
                    .frame(height: 60)

                if selectedTransition == .calmEnvelope {
                    Text(calmPreviewDisplayed)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: CalmTextTransition.phaseLabelSlotWidth, alignment: .center)
                        .blur(radius: calmPreviewBlur)
                        .opacity(calmPreviewOpacity)
                } else if selectedTransition == .breathBlur {
                    Text(calmPreviewDisplayed)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: CalmTextTransition.phaseLabelSlotWidth, alignment: .center)
                        .blur(radius: breathPreviewBlur)
                        .opacity(breathPreviewOpacity)
                } else if selectedTransition == .luminousBlob {
                    let slotW = CalmTextTransition.phaseLabelSlotWidth
                    let slotH = CalmTextTransition.slotLineHeight
                    let capW = max(32, slotW - 2 * CalmTextTransition.luminousCapsuleInsetH)
                    let capH = max(14, slotH - 2 * CalmTextTransition.luminousCapsuleInsetV)
                    ZStack {
                        Capsule()
                            .fill(Color.white.opacity(0.86))
                            .frame(width: capW, height: capH)
                            .blur(radius: CalmTextTransition.luminousBlobShapeBlur)
                            .opacity(luminousPreviewTransitionActive ? luminousPreviewBlobOpacity : luminousPreviewLeadBlobOpacity)
                        Text(calmPreviewDisplayed)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: slotW, height: slotH, alignment: .center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .blur(radius: luminousPreviewTransitionActive ? luminousPreviewTextBlur : luminousPreviewLeadBlur)
                            .opacity(luminousPreviewTransitionActive ? luminousPreviewTextOpacity : 1)
                    }
                    .frame(width: slotW, height: slotH)
                } else if selectedTransition == .slotRoll {
                    VStack(spacing: 0) {
                        Text(reelPreviewTop)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                        Text(reelPreviewBottom)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(width: CalmTextTransition.phaseLabelSlotWidth, height: CalmTextTransition.slotLineHeight, alignment: .top)
                    .clipped()
                    .offset(y: reelPreviewOffset)
                } else {
                    transitionedText(phaseLabels[previewPhaseIndex])
                }
            }

            if selectedTransition == .breathBlur {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Breath blur timing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("Blur starts before “phase end”")
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.2f s", breathApproachLeadSeconds))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: $breathApproachLeadSeconds,
                        in: 0.05...(CalmTextTransition.breathPreviewFakePhaseDuration - 0.1),
                        step: 0.03
                    )
                    Text("Preview treats each label as a \(String(format: "%.1f", CalmTextTransition.breathPreviewFakePhaseDuration))s phase. Larger lead = more sharp time, then blur sooner before the swap. Same value is used in a live session.")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .onChange(of: breathApproachLeadSeconds) { _, _ in
            restartBreathPreviewLoopOnly()
        }
        .onAppear {
            calmPreviewDisplayed = phaseLabels[previewPhaseIndex]
            calmPreviewBlur = 0
            calmPreviewOpacity = 1
            luminousPreviewTextBlur = 0
            luminousPreviewTextOpacity = 1
            luminousPreviewBlobOpacity = 0
            luminousPreviewLeadBlur = 0
            luminousPreviewLeadBlobOpacity = 0
            luminousPreviewTransitionActive = false
            breathPreviewBlur = 0
            breathPreviewOpacity = 1
            let l = phaseLabels[previewPhaseIndex]
            reelPreviewTop = l
            reelPreviewBottom = l
            reelPreviewOffset = 0
            morphPreviewOpacity = 1
            startPreviewCycle()
        }
        .onDisappear {
            previewTimer?.invalidate()
            previewTimer = nil
            breathPreviewLoopToken += 1
        }
        .onChange(of: selectedTransitionRaw) { _, _ in
            previewPhaseIndex = 0
            calmPreviewDisplayed = phaseLabels[0]
            calmPreviewBlur = 0
            calmPreviewOpacity = 1
            luminousPreviewTextBlur = 0
            luminousPreviewTextOpacity = 1
            luminousPreviewBlobOpacity = 0
            luminousPreviewLeadBlur = 0
            luminousPreviewLeadBlobOpacity = 0
            luminousPreviewTransitionActive = false
            breathPreviewBlur = 0
            breathPreviewOpacity = 1
            let l = phaseLabels[0]
            reelPreviewTop = l
            reelPreviewBottom = l
            reelPreviewOffset = 0
            morphPreviewOpacity = 1
            morphBlur = 0
            restartPreviewCycle()
        }
    }

    @ViewBuilder
    private func transitionedText(_ text: String) -> some View {
        switch selectedTransition {
        case .calmEnvelope:
            Text(text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: CalmTextTransition.phaseLabelSlotWidth, alignment: .center)

        case .breathBlur:
            Text(text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: CalmTextTransition.phaseLabelSlotWidth, alignment: .center)

        case .luminousBlob:
            Text(text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: CalmTextTransition.phaseLabelSlotWidth, alignment: .center)

        case .opacity:
            Text(text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: previewPhaseIndex)

        case .interpolate:
            Text(text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: CalmTextTransition.phaseLabelSlotWidth, alignment: .center)
                .contentTransition(.interpolate)
                .animation(
                    .easeInOut(duration: CalmTextTransition.morphPeakDuration + CalmTextTransition.morphSettleDuration),
                    value: previewPhaseIndex
                )
                .blur(radius: morphBlur)
                .opacity(morphPreviewOpacity)

        case .slotRoll:
            Text(text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

        case .pushUp:
            Text(text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: false))
                .animation(.spring(duration: 0.4, bounce: 0.1), value: previewPhaseIndex)

        case .pushDown:
            Text(text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
                .animation(.spring(duration: 0.4, bounce: 0.1), value: previewPhaseIndex)

        case .blurFade:
            Text(text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .id(previewPhaseIndex)
                .transition(AnyTransition.opacity)
                .animation(.easeOut(duration: 0.4), value: previewPhaseIndex)

        case .scale:
            Text(text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .id(previewPhaseIndex)
                .transition(AnyTransition.asymmetric(
                    insertion: AnyTransition.scale(scale: 0.8).combined(with: .opacity),
                    removal: AnyTransition.scale(scale: 1.1).combined(with: .opacity)
                ))
                .animation(.spring(duration: 0.35, bounce: 0.15), value: previewPhaseIndex)
        }
    }

    private func startPreviewCycle() {
        previewTimer?.invalidate()
        previewTimer = nil
        breathPreviewLoopToken += 1

        let style = TextTransitionStyle(rawValue: selectedTransitionRaw) ?? .calmEnvelope
        if style == .breathBlur {
            startBreathPreviewLoopSequence()
            return
        }

        // Luminous ~2.2s+ — keep headroom.
        previewTimer = Timer.scheduledTimer(withTimeInterval: 3.2, repeats: true) { _ in
            let t = TextTransitionStyle(rawValue: selectedTransitionRaw) ?? .calmEnvelope
            if t == .calmEnvelope {
                let next = (previewPhaseIndex + 1) % phaseLabels.count
                runCalmPreviewEnvelope(to: phaseLabels[next]) {
                    previewPhaseIndex = next
                }
            } else if t == .luminousBlob {
                let next = (previewPhaseIndex + 1) % phaseLabels.count
                runLuminousPreviewEnvelope(to: phaseLabels[next]) {
                    previewPhaseIndex = next
                }
            } else if t == .slotRoll {
                runSlotPreviewStep()
            } else if t == .interpolate {
                runMorphPreviewStep()
            } else {
                withAnimation {
                    previewPhaseIndex = (previewPhaseIndex + 1) % phaseLabels.count
                }
            }
        }
    }

    private func startBreathPreviewLoopSequence() {
        breathPreviewLoopToken += 1
        let token = breathPreviewLoopToken
        scheduleBreathPreviewWaitThenCycle(token: token)
    }

    private func scheduleBreathPreviewWaitThenCycle(token: Int) {
        guard TextTransitionStyle(rawValue: selectedTransitionRaw) == .breathBlur else { return }
        breathPreviewBlur = 0
        breathPreviewOpacity = 1
        calmPreviewDisplayed = phaseLabels[previewPhaseIndex]

        let fake = CalmTextTransition.breathPreviewFakePhaseDuration
        let lead = max(0.05, breathApproachLeadSeconds)
        let wait = max(0.08, fake - lead)

        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
            guard token == breathPreviewLoopToken else { return }
            guard TextTransitionStyle(rawValue: selectedTransitionRaw) == .breathBlur else { return }
            let next = (previewPhaseIndex + 1) % phaseLabels.count
            runBreathPreviewEnvelope(to: phaseLabels[next]) {
                guard token == breathPreviewLoopToken else { return }
                previewPhaseIndex = next
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    guard token == breathPreviewLoopToken else { return }
                    scheduleBreathPreviewWaitThenCycle(token: token)
                }
            }
        }
    }

    private func restartBreathPreviewLoopOnly() {
        guard TextTransitionStyle(rawValue: selectedTransitionRaw) == .breathBlur else { return }
        startBreathPreviewLoopSequence()
    }

    private func runMorphPreviewStep() {
        let next = (previewPhaseIndex + 1) % phaseLabels.count
        withAnimation(.easeInOut(duration: CalmTextTransition.morphPeakDuration)) {
            morphBlur = CalmTextTransition.morphBlurPeak
            morphPreviewOpacity = CalmTextTransition.morphOpacityAtPeak
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + CalmTextTransition.morphPeakDuration) {
            previewPhaseIndex = next
            withAnimation(.easeInOut(duration: CalmTextTransition.morphSettleDuration)) {
                morphBlur = 0
                morphPreviewOpacity = 1
            }
        }
    }

    private func runSlotPreviewStep() {
        let next = (previewPhaseIndex + 1) % phaseLabels.count
        reelPreviewTop = reelPreviewBottom
        reelPreviewBottom = phaseLabels[next]
        reelPreviewOffset = 0
        withAnimation(.spring(duration: CalmTextTransition.slotRollDuration, bounce: 0.08)) {
            reelPreviewOffset = -CalmTextTransition.slotLineHeight
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + CalmTextTransition.slotRollDuration + 0.03) {
            previewPhaseIndex = next
            reelPreviewTop = reelPreviewBottom
            reelPreviewOffset = 0
        }
    }

    private func runBreathPreviewEnvelope(to newLabel: String, completion: @escaping () -> Void) {
        breathPreviewToken += 1
        let token = breathPreviewToken
        let inhale = CalmTextTransition.breathInDuration
        let exhale = CalmTextTransition.breathOutDuration
        let opFade = CalmTextTransition.breathOpacityFadeDuration

        withAnimation(.easeInOut(duration: opFade)) {
            breathPreviewOpacity = CalmTextTransition.breathOpacityAtPeak
        }
        withAnimation(.breathIn(duration: inhale)) {
            breathPreviewBlur = CalmTextTransition.breathBlurPeak
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + inhale) {
            guard token == breathPreviewToken else { return }
            calmPreviewDisplayed = newLabel
            withAnimation(.easeInOut(duration: opFade)) {
                breathPreviewOpacity = 1
            }
            withAnimation(.breathOut(duration: exhale)) {
                breathPreviewBlur = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + exhale) {
                guard token == breathPreviewToken else { return }
                completion()
            }
        }
    }

    private func runCalmPreviewEnvelope(to newLabel: String, completion: @escaping () -> Void) {
        calmPreviewToken += 1
        let token = calmPreviewToken
        let half = CalmTextTransition.halfDuration
        withAnimation(.easeInOut(duration: half)) {
            calmPreviewBlur = CalmTextTransition.maxBlurRadius
            calmPreviewOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + half) {
            guard token == calmPreviewToken else { return }
            calmPreviewDisplayed = newLabel
            withAnimation(.easeInOut(duration: half)) {
                calmPreviewBlur = 0
                calmPreviewOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + half) {
                completion()
            }
        }
    }

    private func runLuminousPreviewEnvelope(to newLabel: String, completion: @escaping () -> Void) {
        luminousPreviewToken += 1
        let token = luminousPreviewToken
        let peakBlur = CalmTextTransition.luminousTextBlurPeak
        let outDur = CalmTextTransition.luminousOutgoingCrossfadeDuration
        let inDur = CalmTextTransition.luminousIncomingCrossfadeDuration
        let leadDur = CalmTextTransition.luminousPreviewLeadInDuration

        luminousPreviewTransitionActive = false
        let endTail = CalmTextTransition.preTailBlend(phaseProgress: 1)
        withAnimation(.linear(duration: leadDur)) {
            luminousPreviewLeadBlur = endTail.blur
            luminousPreviewLeadBlobOpacity = endTail.blobOpacity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + leadDur) {
            guard token == luminousPreviewToken else { return }
            luminousPreviewTransitionActive = true
            let carriedBlur = max(luminousPreviewLeadBlur, endTail.blur)
            let carriedBlob = max(luminousPreviewLeadBlobOpacity, endTail.blobOpacity)
            luminousPreviewTextBlur = carriedBlur
            luminousPreviewBlobOpacity = carriedBlob

            withAnimation(.luminousOutgoing(duration: outDur)) {
                luminousPreviewTextBlur = peakBlur
                luminousPreviewTextOpacity = 0
                luminousPreviewBlobOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + outDur) {
                guard token == luminousPreviewToken else { return }
                calmPreviewDisplayed = newLabel
                withAnimation(.luminousIncoming(duration: inDur)) {
                    luminousPreviewBlobOpacity = 0
                    luminousPreviewTextOpacity = 1
                    luminousPreviewTextBlur = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + inDur) {
                    guard token == luminousPreviewToken else { return }
                    luminousPreviewTransitionActive = false
                    luminousPreviewLeadBlur = 0
                    luminousPreviewLeadBlobOpacity = 0
                    completion()
                }
            }
        }
    }

    private func restartPreviewCycle() {
        previewTimer?.invalidate()
        previewTimer = nil
        breathPreviewLoopToken += 1
        startPreviewCycle()
    }

    // MARK: - Helpers

    private func sliderRow(
        _ label: String,
        value: Binding<CGFloat>,
        range: ClosedRange<CGFloat>,
        display: String,
        transform: ((CGFloat) -> CGFloat)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                let displayed = transform?(value.wrappedValue) ?? value.wrappedValue
                Text(String(format: display, displayed))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }

    private var codeString: String {
        """
        expandedWidth: \(Int(shapeWidth))
        expandedHeight: \(Int(shapeHeight))
        expandedTopRadius: \(Int(topRadius))
        expandedBottomRadius: \(Int(bottomRadius))
        straightMult: \(String(format: "%.2f", straightMult))
        curveMult: \(String(format: "%.2f", curveMult))
        overshootPct: \(String(format: "%.2f", overshootPct))
        curveBlend: \(String(format: "%.2f", curveBlend))
        """
    }

    private var codeBlock: some View {
        Text(codeString)
            .font(.system(size: 10, design: .monospaced))
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Tunable Shape

private struct TunableNotchShape: Shape {
    var shapeWidth: CGFloat
    var shapeHeight: CGFloat
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat
    var straightMult: CGFloat
    var curveMult: CGFloat
    var overshootPct: CGFloat
    var curveBlend: CGFloat

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let left = cx - shapeWidth / 2
        let right = cx + shapeWidth / 2
        let topR = max(topCornerRadius, 0)
        let botR = max(bottomCornerRadius, 0)
        let bodyL = left + topR
        let bodyR = right - topR

        let straightH = topR * straightMult
        let curveH = topR * curveMult
        let overshoot = (straightH + curveH) * overshootPct
        let top = rect.minY - overshoot
        let bottom = rect.minY + shapeHeight

        // curveBlend controls how early the inward bend starts.
        // 0.55 = default (symmetric), lower = bends sooner (softer at bezel)
        let c1 = curveBlend
        let c2 = 1.0 - c1

        var p = Path()

        p.move(to: CGPoint(x: left, y: top))
        p.addLine(to: CGPoint(x: right, y: top))

        // Right ear
        p.addLine(to: CGPoint(x: right, y: top + straightH))
        p.addCurve(
            to: CGPoint(x: bodyR, y: top + straightH + curveH),
            control1: CGPoint(x: right, y: top + straightH + curveH * c1),
            control2: CGPoint(x: bodyR, y: top + straightH + curveH * c2)
        )

        p.addLine(to: CGPoint(x: bodyR, y: bottom - botR))

        p.addCurve(
            to: CGPoint(x: bodyR - botR, y: bottom),
            control1: CGPoint(x: bodyR, y: bottom - botR * 0.44),
            control2: CGPoint(x: bodyR - botR * 0.44, y: bottom)
        )

        p.addLine(to: CGPoint(x: bodyL + botR, y: bottom))

        p.addCurve(
            to: CGPoint(x: bodyL, y: bottom - botR),
            control1: CGPoint(x: bodyL + botR * 0.44, y: bottom),
            control2: CGPoint(x: bodyL, y: bottom - botR * 0.44)
        )

        p.addLine(to: CGPoint(x: bodyL, y: top + straightH + curveH))

        // Left ear
        p.addCurve(
            to: CGPoint(x: left, y: top + straightH),
            control1: CGPoint(x: bodyL, y: top + straightH + curveH * c2),
            control2: CGPoint(x: left, y: top + straightH + curveH * c1)
        )
        p.addLine(to: CGPoint(x: left, y: top))

        p.closeSubpath()
        return p
    }
}
