import SwiftUI

@Observable
final class BreathingSessionViewModel {

    // MARK: - Published State

    var currentPhase: BreathingPhase = .inhale
    var phaseProgress: CGFloat = 0
    var overallProgress: CGFloat = 0
    var sessionProgress: CGFloat = 0
    var isActive: Bool = false
    var cyclesCompleted: Int = 0
    var shouldDismiss: Bool = false

    var onSessionComplete: (() -> Void)?

    // MARK: - Configuration

    private let preset: BreathingPreset
    private let sessionDuration: TimeInterval

    // MARK: - Internal Timing

    private var sessionStartTime: Date?
    private var phaseStartTime: Date?
    private var timer: Timer?
    private var phasesCompleted: Int = 0

    init(settings: UserSettings) {
        self.preset = settings.currentPreset
        self.sessionDuration = settings.sessionDurationSeconds
    }

    func start() {
        isActive = true
        sessionStartTime = Date()
        startPhase(.inhale)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) {
            [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    func stop() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Tick

    private func tick() {
        guard isActive,
              let sessionStart = sessionStartTime,
              let phaseStart = phaseStartTime else { return }

        let now = Date()

        // Session progress
        let sessionElapsed = now.timeIntervalSince(sessionStart)
        sessionProgress = min(CGFloat(sessionElapsed / sessionDuration), 1.0)

        if sessionProgress >= 1.0 {
            stop()
            onSessionComplete?()
            return
        }

        // Phase progress
        let phaseDuration = preset.duration(for: currentPhase)
        let phaseElapsed = now.timeIntervalSince(phaseStart)
        phaseProgress = min(CGFloat(phaseElapsed / phaseDuration), 1.0)

        // Overall cycle progress (0-1 around the square)
        let cycleDuration = preset.totalCycleDuration
        let cycleElapsed = sessionElapsed.truncatingRemainder(dividingBy: cycleDuration)
        overallProgress = CGFloat(cycleElapsed / cycleDuration)

        // Advance phase
        if phaseElapsed >= phaseDuration {
            phasesCompleted += 1
            if phasesCompleted % 4 == 0 {
                cyclesCompleted = phasesCompleted / 4
            }
            startPhase(currentPhase.next)
        }
    }

    private func startPhase(_ phase: BreathingPhase) {
        currentPhase = phase
        phaseStartTime = Date()
        phaseProgress = 0
    }

    // MARK: - Formatted Time

    var timeRemaining: String {
        let elapsed = sessionStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let remaining = max(0, sessionDuration - elapsed)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
