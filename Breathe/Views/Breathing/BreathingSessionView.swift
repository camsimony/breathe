import SwiftUI

/// Fallback breathing view for non-notch Macs (glass/vibrancy style).
/// Not used directly anymore — NotchOverlayView is the main entry point.
/// Kept for potential future use with non-notch display mode.
struct BreathingSessionView: View {
    let viewModel: BreathingSessionViewModel
    let hasNotch: Bool
    let onDismiss: () -> Void

    @State private var isExpanded = false

    var body: some View {
        ZStack {
            glassBackground

            VStack(spacing: 0) {
                Spacer().frame(height: 16)
                Spacer()
                SquarePathView(viewModel: viewModel)
                Spacer()
                Spacer().frame(height: 16)
            }
        }
        .opacity(isExpanded ? 1 : 0)
        .scaleEffect(isExpanded ? 1 : 0.96, anchor: .top)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(duration: 0.4, bounce: 0.08)) {
                    isExpanded = true
                }
            }
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
    }

    private var glassBackground: some View {
        ZStack {
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
            Color.black.opacity(0.15)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}
