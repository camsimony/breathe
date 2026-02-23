import Foundation

struct BreathingPreset: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let inhale: TimeInterval
    let holdIn: TimeInterval
    let exhale: TimeInterval
    let holdOut: TimeInterval

    var totalCycleDuration: TimeInterval {
        inhale + holdIn + exhale + holdOut
    }

    func duration(for phase: BreathingPhase) -> TimeInterval {
        switch phase {
        case .inhale: inhale
        case .holdIn: holdIn
        case .exhale: exhale
        case .holdOut: holdOut
        }
    }

    static let beginner = BreathingPreset(
        id: "beginner", name: "Beginner",
        inhale: 5, holdIn: 5, exhale: 5, holdOut: 5
    )

    static let classic = BreathingPreset(
        id: "classic", name: "Classic",
        inhale: 7, holdIn: 7, exhale: 7, holdOut: 7
    )

    static let advanced = BreathingPreset(
        id: "advanced", name: "Advanced",
        inhale: 10, holdIn: 10, exhale: 10, holdOut: 10
    )

    static let allPresets: [BreathingPreset] = [.beginner, .classic, .advanced]
}
