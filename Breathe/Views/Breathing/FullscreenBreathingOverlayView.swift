import SwiftUI

/// Full-screen dimmed overlay with a large centered box-breathing UI (alternate to `NotchOverlayView`).
struct FullscreenBreathingOverlayView: View {
    let viewModel: BreathingSessionViewModel
    let settings: UserSettings
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dimOpacity: CGFloat = 0
    /// Extra blur on the scrim during countdown (opacity + transform-adjacent; eased down when breathing starts).
    @State private var backdropBlur: CGFloat = 0
    @State private var contentRevealed = false
    @State private var countdownValue: Int = 3
    @State private var countdownBlur: CGFloat = CalmTextTransition.maxBlurRadius
    @State private var countdownOpacity: CGFloat = 0
    @State private var postSessionMoodActive = false
    @State private var moodContentRevealed = false
    @State private var collapseStarted = false

    private let moodOptions: [(value: Int, emoji: String)] = [
        (1, "🙁"),
        (2, "😐"),
        (3, "😊"),
    ]

    private let squarePathScale: CGFloat = 1.78
    private let squarePathBaseSize: CGFloat = 152

    var body: some View {
        ZStack {
            ZStack {
                VisualEffectBackground(
                    material: .hudWindow,
                    blendingMode: .behindWindow
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

                Color.black.opacity(0.80)
                    .ignoresSafeArea()
            }
            .blur(radius: backdropBlur)
            .opacity(dimOpacity)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Text("\(countdownValue)")
                        .font(.system(size: 72, weight: .regular, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .frame(width: CalmTextTransition.countdownDigitSlotWidth * 1.35, alignment: .center)
                        .blur(radius: countdownBlur)
                        .opacity(countdownOpacity)

                    SquarePathView(viewModel: viewModel, squareSize: squarePathBaseSize)
                        .scaleEffect(squarePathScale * (contentRevealed ? 1 : 0.96))
                        .opacity(contentRevealed ? 1 : 0)
                        .blur(radius: contentRevealed ? 0 : 8)

                    postSessionMoodStack
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                startCountdown()
            }
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { dismissWithAnimation() }
        }
        .onChange(of: viewModel.awaitingPostSessionMood) { _, pending in
            if pending { beginPostSessionMoodTransition() }
        }
        .onChange(of: viewModel.pendingMoodShortcut) { _, value in
            guard let value else { return }
            viewModel.pendingMoodShortcut = nil
            submitPostSessionMood(value)
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.escape) {
            if postSessionMoodActive, moodContentRevealed {
                submitPostSessionMood(nil)
                return .handled
            }
            dismissWithAnimation()
            return .handled
        }
        .onKeyPress { press in
            guard postSessionMoodActive, moodContentRevealed,
                  !viewModel.statsRecorded else { return .ignored }
            let key = press.key
            if key == KeyEquivalent("1") {
                submitPostSessionMood(1)
                return .handled
            }
            if key == KeyEquivalent("2") {
                submitPostSessionMood(2)
                return .handled
            }
            if key == KeyEquivalent("3") {
                submitPostSessionMood(3)
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Post-session mood

    private var postSessionMoodStack: some View {
        Group {
            if postSessionMoodActive {
                VStack(spacing: 14) {
                    Text("How do you feel?")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    HStack(spacing: 28) {
                        ForEach(moodOptions, id: \.value) { option in
                            Button {
                                submitPostSessionMood(option.value)
                            } label: {
                                VStack(spacing: 6) {
                                    Text(option.emoji)
                                        .font(.system(size: 44))
                                        .accessibilityHidden(true)
                                    Text("\(option.value)")
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                        .monospacedDigit()
                                }
                                .frame(minWidth: 60)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(moodAccessibilityLabel(for: option.value))
                            .accessibilityHint("Shortcut: \(option.value)")
                        }
                    }

                    Button("Skip") {
                        submitPostSessionMood(nil)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                }
                .multilineTextAlignment(.center)
                .opacity(moodContentRevealed ? 1 : 0)
                .blur(radius: moodContentRevealed ? 0 : 8)
                .scaleEffect(moodContentRevealed ? 1 : 0.96)
            }
        }
    }

    private func moodAccessibilityLabel(for value: Int) -> String {
        switch value {
        case 1: return "Not great"
        case 2: return "Okay"
        case 3: return "Good"
        default: return "Mood \(value)"
        }
    }

    private func beginPostSessionMoodTransition() {
        guard !postSessionMoodActive else { return }
        viewModel.postSessionMoodInputReady = false
        postSessionMoodActive = true
        moodContentRevealed = false

        let breathingOut = Animation.easeIn(duration: 0.35)
        withAnimation(breathingOut) {
            contentRevealed = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard viewModel.awaitingPostSessionMood else { return }
            withAnimation(.easeOut(duration: 0.35)) {
                moodContentRevealed = true
            }
            viewModel.postSessionMoodInputReady = true
        }
    }

    private func submitPostSessionMood(_ mood: Int?) {
        guard viewModel.awaitingPostSessionMood, !viewModel.statsRecorded else { return }
        viewModel.statsRecorded = true
        viewModel.postSessionMoodInputReady = false

        withAnimation(.easeIn(duration: 0.35)) {
            moodContentRevealed = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            viewModel.awaitingPostSessionMood = false
            postSessionMoodActive = false
            settings.recordBreathingSession(
                actualSeconds: viewModel.plannedSessionSeconds,
                countsAsFullSession: true,
                mood: mood
            )
            viewModel.shouldDismiss = true
        }
    }

    // MARK: - Countdown

    private func startCountdown() {
        let ramp = CalmTextTransition.countdownFocusRampDuration
        if reduceMotion {
            dimOpacity = 1
            backdropBlur = 0
        } else {
            // design-eng: steady linear ramp over the countdown = predictable “settle into focus.”
            withAnimation(.linear(duration: ramp)) {
                dimOpacity = 1
                backdropBlur = 12
            }
        }

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
        if !reduceMotion {
            // Ease backdrop blur down so the room stays softened but the exercise UI reads sharp.
            withAnimation(.easeOut(duration: 0.42)) {
                backdropBlur = 4
            }
        }
        viewModel.start()
        withAnimation(.easeOut(duration: 0.35)) {
            contentRevealed = true
        }
    }

    // MARK: - Dismiss

    private func dismissWithAnimation() {
        guard !collapseStarted else { return }
        collapseStarted = true
        viewModel.postSessionMoodInputReady = false

        withAnimation(.easeIn(duration: 0.28)) {
            contentRevealed = false
            moodContentRevealed = false
        }

        withAnimation(.easeIn(duration: 0.42)) {
            dimOpacity = 0
            backdropBlur = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            onDismiss()
        }
    }
}
