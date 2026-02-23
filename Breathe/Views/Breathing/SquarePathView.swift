import SwiftUI

private func warpProgress(_ p: CGFloat, phi: CGFloat) -> CGFloat {
    let a: CGFloat = 0.6
    let freq = 8 * CGFloat.pi
    return p - a * (sin(freq * (p - phi)) + sin(freq * phi)) / freq
}

private let tailLength: CGFloat = 0.40

struct SquarePathView: View {
    let viewModel: BreathingSessionViewModel
    let squareSize: CGFloat = 140
    private let cr: CGFloat = 10
    @AppStorage("textTransitionStyle") private var transitionStyleRaw: String = "pushUp"
    private var transitionStyle: TextTransitionStyle {
        TextTransitionStyle(rawValue: transitionStyleRaw) ?? .pushUp
    }
    @State private var morphBlur: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            phaseLabel("Hold", isActive: viewModel.currentPhase == .holdIn)
                .padding(.bottom, 12)

            HStack(spacing: 0) {
                phaseLabel("Inhale", isActive: viewModel.currentPhase == .inhale)
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
                        phaseText(viewModel.currentPhase.label)

                        Text(viewModel.timeRemaining)
                            .font(.system(size: 12, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .frame(width: squareSize, height: squareSize)

                Spacer().frame(width: 14)

                phaseLabel("Exhale", isActive: viewModel.currentPhase == .exhale)
                    .frame(width: 54, alignment: .leading)
            }

            phaseLabel("Hold", isActive: viewModel.currentPhase == .holdOut)
                .padding(.top, 12)
        }
        .onChange(of: viewModel.currentPhase) { _, _ in
            guard transitionStyle == .interpolate else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                morphBlur = 6
            }
            withAnimation(.easeIn(duration: 0.6).delay(0.25)) {
                morphBlur = 0
            }
        }
    }

    // MARK: - Center Phase Text

    @ViewBuilder
    private func phaseText(_ text: String) -> some View {
        let font = Font.system(size: 20, weight: .semibold, design: .rounded)
        switch transitionStyle {
        case .opacity:
            Text(text).font(font).foregroundStyle(.white)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: viewModel.currentPhase)
        case .interpolate:
            Text(text).font(font).foregroundStyle(.white)
                .contentTransition(.interpolate)
                .animation(.easeInOut(duration: 0.6), value: viewModel.currentPhase)
                .blur(radius: morphBlur)
        case .pushUp:
            Text(text).font(font).foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: false))
                .animation(.spring(duration: 0.4, bounce: 0.1), value: viewModel.currentPhase)
        case .pushDown:
            Text(text).font(font).foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
                .animation(.spring(duration: 0.4, bounce: 0.1), value: viewModel.currentPhase)
        case .blurFade:
            Text(text).font(font).foregroundStyle(.white)
                .id(viewModel.currentPhase)
                .transition(AnyTransition.opacity)
                .animation(.easeOut(duration: 0.4), value: viewModel.currentPhase)
        case .scale:
            Text(text).font(font).foregroundStyle(.white)
                .id(viewModel.currentPhase)
                .transition(AnyTransition.asymmetric(
                    insertion: AnyTransition.scale(scale: 0.8).combined(with: .opacity),
                    removal: AnyTransition.scale(scale: 1.1).combined(with: .opacity)
                ))
                .animation(.spring(duration: 0.35, bounce: 0.15), value: viewModel.currentPhase)
        }
    }

    // MARK: - Phase Label

    private func phaseLabel(_ text: String, isActive: Bool) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(isActive ? .white.opacity(0.7) : .white.opacity(0.15))
            .animation(.easeOut(duration: 0.2), value: isActive)
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
