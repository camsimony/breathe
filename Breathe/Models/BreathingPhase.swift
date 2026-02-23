import Foundation

enum BreathingPhase: Int, CaseIterable, Equatable {
    case inhale
    case holdIn
    case exhale
    case holdOut

    var label: String {
        switch self {
        case .inhale: "Inhale"
        case .holdIn: "Hold"
        case .exhale: "Exhale"
        case .holdOut: "Hold"
        }
    }

    var next: BreathingPhase {
        BreathingPhase(rawValue: (rawValue + 1) % 4)!
    }
}
