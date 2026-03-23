import SwiftUI

@Observable
final class UserSettings {
    // MARK: - Breathing Timing

    @ObservationIgnored
    @AppStorage("selectedPresetId") var selectedPresetId: String = "classic"

    @ObservationIgnored
    @AppStorage("customInhale") var customInhale: Double = 4

    @ObservationIgnored
    @AppStorage("customHoldIn") var customHoldIn: Double = 4

    @ObservationIgnored
    @AppStorage("customExhale") var customExhale: Double = 4

    @ObservationIgnored
    @AppStorage("customHoldOut") var customHoldOut: Double = 4

    var currentPreset: BreathingPreset {
        switch selectedPresetId {
        case "beginner": return .beginner
        case "classic": return .classic
        case "advanced": return .advanced
        case "custom":
            return BreathingPreset(
                id: "custom", name: "Custom",
                inhale: customInhale, holdIn: customHoldIn,
                exhale: customExhale, holdOut: customHoldOut
            )
        default: return .classic
        }
    }

    // MARK: - Session

    @ObservationIgnored
    @AppStorage("sessionDurationMinutes") var sessionDurationMinutes: Int = 5

    @ObservationIgnored
    @AppStorage("useSessionCycles") var useSessionCycles: Bool = false

    @ObservationIgnored
    @AppStorage("sessionCycleCount") var sessionCycleCount: Int = 4

    var sessionDurationSeconds: TimeInterval {
        if useSessionCycles {
            return TimeInterval(sessionCycleCount) * currentPreset.totalCycleDuration
        }
        return TimeInterval(sessionDurationMinutes * 60)
    }

    // MARK: - Reminders

    @ObservationIgnored
    @AppStorage("reminderFrequency") var reminderFrequencyRaw: String = "hourly"

    @ObservationIgnored
    @AppStorage("quietHoursEnabled") var quietHoursEnabled: Bool = false

    @ObservationIgnored
    @AppStorage("quietHoursStart") var quietHoursStartMinutes: Int = 1320 // 22:00

    @ObservationIgnored
    @AppStorage("quietHoursEnd") var quietHoursEndMinutes: Int = 480 // 08:00

    var reminderFrequency: ReminderFrequency {
        get { ReminderFrequency(rawValue: reminderFrequencyRaw) ?? .hourly }
        set { reminderFrequencyRaw = newValue.rawValue }
    }

    // MARK: - Appearance

    @ObservationIgnored
    @AppStorage("textTransitionStyle") var textTransitionStyleRaw: String = "calmEnvelope"

    var textTransitionStyle: TextTransitionStyle {
        get { TextTransitionStyle(rawValue: textTransitionStyleRaw) ?? .calmEnvelope }
        set { textTransitionStyleRaw = newValue.rawValue }
    }

    /// Seconds before a phase ends that breath-blur may begin (tunable in Shape Tuner).
    @ObservationIgnored
    @AppStorage("breathApproachLeadSeconds") var breathApproachLeadSeconds: Double = 1.0

    // MARK: - General

    @ObservationIgnored
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = true
}

enum TextTransitionStyle: String, CaseIterable, Identifiable {
    case calmEnvelope = "calmEnvelope"
    /// Blur smears into a bright blob; opacity never hits zero (no full blackout), then sharpens.
    case luminousBlob = "luminousBlob"
    /// Long inhale blur into unreadable peak, swap, long exhale blur-out to the next word (no blob layer).
    case breathBlur = "breathBlur"
    case opacity = "opacity"
    case interpolate = "interpolate"
    case slotRoll = "slotRoll"
    case pushUp = "pushUp"
    case pushDown = "pushDown"
    case blurFade = "blurFade"
    case scale = "scale"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .calmEnvelope: return "Calm blur"
        case .luminousBlob: return "Luminous blob"
        case .breathBlur: return "Breath blur"
        case .opacity: return "Crossfade"
        case .interpolate: return "Morph"
        case .slotRoll: return "Slot roll"
        case .pushUp: return "Push Up"
        case .pushDown: return "Push Down"
        case .blurFade: return "Blur Dissolve"
        case .scale: return "Scale"
        }
    }
}
