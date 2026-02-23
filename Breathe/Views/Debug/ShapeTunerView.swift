import SwiftUI

struct ShapeTunerView: View {
    @State private var shapeWidth: CGFloat = 290
    @State private var shapeHeight: CGFloat = 240
    @State private var topRadius: CGFloat = 10
    @State private var bottomRadius: CGFloat = 30
    @State private var straightMult: CGFloat = 1.0
    @State private var curveMult: CGFloat = 2.3
    @State private var overshootPct: CGFloat = 0.61
    @State private var curveBlend: CGFloat = 0.55

    @AppStorage("textTransitionStyle") private var selectedTransitionRaw: String = "pushUp"
    private var selectedTransition: TextTransitionStyle {
        get { TextTransitionStyle(rawValue: selectedTransitionRaw) ?? .pushUp }
    }
    @State private var previewPhaseIndex: Int = 0
    @State private var previewTimer: Timer?
    @State private var morphBlur: CGFloat = 0

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

                transitionedText(phaseLabels[previewPhaseIndex])
            }
            .onAppear { startPreviewCycle() }
            .onDisappear { previewTimer?.invalidate() }
            .onChange(of: selectedTransitionRaw) { _, _ in
                previewPhaseIndex = 0
                restartPreviewCycle()
            }
        }
    }

    @ViewBuilder
    private func transitionedText(_ text: String) -> some View {
        switch selectedTransition {
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
                .contentTransition(.interpolate)
                .animation(.easeInOut(duration: 0.6), value: previewPhaseIndex)
                .blur(radius: morphBlur)

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
        previewTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            if selectedTransition == .interpolate {
                withAnimation(.easeOut(duration: 0.25)) { morphBlur = 6 }
                withAnimation(.easeIn(duration: 0.6).delay(0.25)) { morphBlur = 0 }
            }
            withAnimation {
                previewPhaseIndex = (previewPhaseIndex + 1) % phaseLabels.count
            }
        }
    }

    private func restartPreviewCycle() {
        previewTimer?.invalidate()
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
