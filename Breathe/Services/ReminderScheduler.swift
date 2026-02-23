import UserNotifications

final class ReminderScheduler {
    private let center = UNUserNotificationCenter.current()

    func configure(with settings: UserSettings) {
        requestPermission()
        reschedule(with: settings)
    }

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func reschedule(with settings: UserSettings) {
        center.removeAllPendingNotificationRequests()

        let frequency = settings.reminderFrequency
        guard frequency != .off else { return }

        switch frequency {
        case .every30Min:
            scheduleRepeating(intervalMinutes: 30, settings: settings)
        case .hourly:
            scheduleRepeating(intervalMinutes: 60, settings: settings)
        case .every2Hours:
            scheduleRepeating(intervalMinutes: 120, settings: settings)
        case .threeTimesDaily:
            scheduleFixedTimes(hours: [9, 13, 17], settings: settings)
        case .onceDaily:
            scheduleFixedTimes(hours: [10], settings: settings)
        case .off:
            break
        }
    }

    // MARK: - Scheduling

    private func scheduleRepeating(intervalMinutes: Int, settings: UserSettings) {
        let content = makeContent()
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(intervalMinutes * 60),
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "breathe.reminder.repeating",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    private func scheduleFixedTimes(hours: [Int], settings: UserSettings) {
        for (index, hour) in hours.enumerated() {
            if settings.quietHoursEnabled {
                let minuteOfDay = hour * 60
                if isInQuietHours(minuteOfDay: minuteOfDay, settings: settings) {
                    continue
                }
            }

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            let request = UNNotificationRequest(
                identifier: "breathe.reminder.fixed.\(index)",
                content: makeContent(),
                trigger: trigger
            )
            center.add(request)
        }
    }

    private func makeContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Time to Breathe"
        content.body = "Take a moment for box breathing."
        content.sound = .default
        content.categoryIdentifier = "BREATHING_REMINDER"
        return content
    }

    private func isInQuietHours(minuteOfDay: Int, settings: UserSettings) -> Bool {
        let start = settings.quietHoursStartMinutes
        let end = settings.quietHoursEndMinutes
        if start <= end {
            return minuteOfDay >= start && minuteOfDay < end
        } else {
            // Wraps past midnight (e.g., 22:00 - 08:00)
            return minuteOfDay >= start || minuteOfDay < end
        }
    }
}
