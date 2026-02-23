import Foundation

enum ReminderFrequency: String, CaseIterable, Identifiable {
    case every30Min = "every30min"
    case hourly = "hourly"
    case every2Hours = "every2hours"
    case threeTimesDaily = "3xdaily"
    case onceDaily = "onceDaily"
    case off = "off"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .every30Min: "Every 30 minutes"
        case .hourly: "Every hour"
        case .every2Hours: "Every 2 hours"
        case .threeTimesDaily: "3 times daily"
        case .onceDaily: "Once daily"
        case .off: "Off"
        }
    }
}
