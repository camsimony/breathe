import SwiftUI

struct NotchOverlayView: View {
    let viewModel: BreathingSessionViewModel
    let notchInfo: NotchInfo
    let onDismiss: () -> Void

    @State private var isExpanded = false
    @State private var contentRevealed = false
    @State private var countdownValue: Int = 3
    @State private var countdownVisible = false
    @State private var countdownFinished = false

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
                            .font(.system(size: 48, weight: .light, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .opacity(countdownVisible ? 1 : 0)
                            .scaleEffect(countdownVisible ? 1 : 0.5)
                            .blur(radius: countdownVisible ? 0 : 4)

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

    // MARK: - Countdown

    private func startCountdown() {
        showNumber(3) {
            showNumber(2) {
                showNumber(1) {
                    finishCountdown()
                }
            }
        }
    }

    private func showNumber(_ n: Int, completion: @escaping () -> Void) {
        countdownValue = n
        withAnimation(.easeOut(duration: 0.25)) {
            countdownVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeIn(duration: 0.2)) {
                countdownVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                completion()
            }
        }
    }

    private func finishCountdown() {
        countdownFinished = true
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
