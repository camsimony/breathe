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

    /// Increments only when `currentPhase` changes — reliable `onChange` for blur envelope in hosted views.
    private(set) var phaseGeneration: Int = 0
    /// Once per phase, shortly before the phase ends — lets breath-blur UI start inhale before `phaseGeneration`.
    private(set) var phaseApproachSignal: Int = 0

    var onSessionComplete: (() -> Void)?

    // MARK: - Configuration

    private let settings: UserSettings
    private let preset: BreathingPreset
    private let sessionDuration: TimeInterval

    // MARK: - Internal Timing

    private var sessionStartTime: Date?
    private var phaseStartTime: Date?
    private var timer: Timer?
    private var phasesCompleted: Int = 0
    private var emittedPhaseApproach: Bool = false

    init(settings: UserSettings) {
        self.settings = settings
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

        let lead = max(0.05, settings.breathApproachLeadSeconds)
        if !emittedPhaseApproach, phaseDuration > lead + 0.08, phaseElapsed >= phaseDuration - lead {
            emittedPhaseApproach = true
            phaseApproachSignal += 1
        }

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
        if currentPhase != phase {
            phaseGeneration += 1
        }
        currentPhase = phase
        phaseStartTime = Date()
        phaseProgress = 0
        emittedPhaseApproach = false
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
