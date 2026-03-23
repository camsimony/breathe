import SwiftUI

struct NotchOverlayView: View {
    let viewModel: BreathingSessionViewModel
    let notchInfo: NotchInfo
    let onDismiss: () -> Void

    @State private var isExpanded = false
    @State private var contentRevealed = false
    @State private var countdownValue: Int = 3
    @State private var countdownBlur: CGFloat = CalmTextTransition.maxBlurRadius
    @State private var countdownOpacity: CGFloat = 0

    private var notchWidth: CGFloat { notchInfo.notchWidth }
    private var notchHeight: CGFloat { notchInfo.notchHeight }

    private let expandedWidth: CGFloat = 380
    private var expandedHeight: CGFloat {
        let topClearance = notchInfo.hasNotch ? notchHeight + 6 : 12
        let contentHeight: CGFloat = 194
        let bottomPadding: CGFloat = 20
        return topClearance + contentHeight + bottomPadding
    }

    private let closedTopRadius: CGFloat = 6
    private let closedBottomRadius: CGFloat = 14
    private let expandedTopRadius: CGFloat = 15
    private let expandedBottomRadius: CGFloat = 29

    var body: some View {
        Color.black
            .overlay {
                VStack(spacing: 0) {
                    Spacer().frame(height: notchInfo.hasNotch ? notchHeight + 6 : 12)

                    Spacer()

                    ZStack {
                        Text("\(countdownValue)")
                            .font(.system(size: 48, weight: .regular, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .frame(width: CalmTextTransition.countdownDigitSlotWidth, alignment: .center)
                            .blur(radius: countdownBlur)
                            .opacity(countdownOpacity)

                        SquarePathView(viewModel: viewModel)
                            .opacity(contentRevealed ? 1 : 0)
                            .blur(radius: contentRevealed ? 0 : 8)
                            .scaleEffect(contentRevealed ? 1 : 0.96)
                    }

                    Spacer()

                    Spacer().frame(height: 20)
                }
            }
            .frame(width: expandedWidth, height: expandedHeight)
            .clipShape(
                NotchShape(
                    shapeWidth: isExpanded ? expandedWidth : notchWidth,
                    shapeHeight: isExpanded ? expandedHeight : notchHeight,
                    topCornerRadius: isExpanded ? expandedTopRadius : closedTopRadius,
                    bottomCornerRadius: isExpanded ? expandedBottomRadius : closedBottomRadius
                )
            )
            .shadow(color: .black.opacity(isExpanded ? 0.4 : 0), radius: 16, y: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                DispatchQueue.main.async {
                    withAnimation(.spring(duration: 0.3, bounce: 0)) {
                        isExpanded = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        startCountdown()
                    }
                }
            }
            .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss { dismissWithAnimation() }
            }
            .onKeyPress(.escape) {
                dismissWithAnimation()
                return .handled
            }
    }

    // MARK: - Countdown (calm blur envelope)

    private func startCountdown() {
        countdownValue = 3
        countdownBlur = CalmTextTransition.maxBlurRadius
        countdownOpacity = 0
        withAnimation(.easeInOut(duration: CalmTextTransition.halfDuration)) {
            countdownBlur = 0
            countdownOpacity = 1
        }

        let h = CalmTextTransition.halfDuration
        let hold = CalmTextTransition.holdAfterSharp

        DispatchQueue.main.asyncAfter(deadline: .now() + h + hold) {
            blurOutSwapBlurIn(nextValue: 2) {
                DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
                    blurOutSwapBlurIn(nextValue: 1) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
                            blurOutOnly { finishCountdown() }
                        }
                    }
                }
            }
        }
    }

    private func blurOutSwapBlurIn(nextValue: Int, completion: @escaping () -> Void) {
        let h = CalmTextTransition.halfDuration
        withAnimation(.easeInOut(duration: h)) {
            countdownBlur = CalmTextTransition.maxBlurRadius
            countdownOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + h) {
            countdownValue = nextValue
            withAnimation(.easeInOut(duration: h)) {
                countdownBlur = 0
                countdownOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + h, execute: completion)
        }
    }

    private func blurOutOnly(completion: @escaping () -> Void) {
        let h = CalmTextTransition.halfDuration
        withAnimation(.easeInOut(duration: h)) {
            countdownBlur = CalmTextTransition.maxBlurRadius
            countdownOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + h, execute: completion)
    }

    private func finishCountdown() {
        viewModel.start()
        withAnimation(.easeOut(duration: 0.35)) {
            contentRevealed = true
        }
    }

    // MARK: - Dismiss

    private func dismissWithAnimation() {
        guard isExpanded else { return }

        withAnimation(.easeIn(duration: 0.15)) {
            contentRevealed = false
        }

        withAnimation(.spring(duration: 0.3, bounce: 0).delay(0.08)) {
            isExpanded = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
}
