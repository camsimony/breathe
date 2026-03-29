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

    @ObservationIgnored
    @AppStorage("breathingPresentationStyle") private var breathingPresentationStyleRaw: String = BreathingPresentationStyle.notch.rawValue

    var breathingPresentationStyle: BreathingPresentationStyle {
        get { BreathingPresentationStyle(rawValue: breathingPresentationStyleRaw) ?? .notch }
        set { breathingPresentationStyleRaw = newValue.rawValue }
    }

    // MARK: - General

    @ObservationIgnored
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = true

    // MARK: - Session statistics (Home)

    @ObservationIgnored
    @AppStorage("statsTotalSeconds") var statsTotalSeconds: Double = 0

    @ObservationIgnored
    @AppStorage("statsWeekSessionCount") var statsWeekSessionCount: Int = 0

    @ObservationIgnored
    @AppStorage("statsWeekToken") private var statsWeekToken: String = ""

    @ObservationIgnored
    @AppStorage("statsTotalFullSessions") var statsTotalFullSessions: Int = 0

    @ObservationIgnored
    @AppStorage("statsMoodSum") var statsMoodSum: Int = 0

    @ObservationIgnored
    @AppStorage("statsMoodCount") var statsMoodCount: Int = 0

    func recordBreathingSession(actualSeconds: TimeInterval, countsAsFullSession: Bool, mood: Int?) {
        guard actualSeconds >= 1 else { return }
        syncStatsWeekIfNeeded()
        statsTotalSeconds += actualSeconds
        if countsAsFullSession {
            statsWeekSessionCount += 1
            statsTotalFullSessions += 1
        }
        if let mood, (1...3).contains(mood) {
            statsMoodSum += mood
            statsMoodCount += 1
        }
    }

    private func syncStatsWeekIfNeeded() {
        let cal = Calendar.current
        let now = Date()
        let y = cal.component(.yearForWeekOfYear, from: now)
        let w = cal.component(.weekOfYear, from: now)
        let token = "\(y)-\(w)"
        if statsWeekToken != token {
            statsWeekToken = token
            statsWeekSessionCount = 0
        }
    }
}

enum BreathingPresentationStyle: String, CaseIterable, Identifiable {
    case notch = "notch"
    case fullscreenOverlay = "overlay"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notch: "Notch"
        case .fullscreenOverlay: "Overlay"
        }
    }
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
