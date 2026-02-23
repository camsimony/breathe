import SwiftUI

struct RemindersSection: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Frequency") {
                Picker("Remind me", selection: $settings.reminderFrequencyRaw) {
                    ForEach(ReminderFrequency.allCases) { freq in
                        Text(freq.displayName).tag(freq.rawValue)
                    }
                }
            }

            Section("Quiet Hours") {
                Toggle("Enable quiet hours", isOn: $settings.quietHoursEnabled)

                if settings.quietHoursEnabled {
                    DatePicker(
                        "From",
                        selection: quietHoursStartBinding,
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        "Until",
                        selection: quietHoursEndBinding,
                        displayedComponents: .hourAndMinute
                    )
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Time Bindings

    /// Convert minutes-since-midnight Int to/from Date for DatePicker
    private var quietHoursStartBinding: Binding<Date> {
        Binding(
            get: { dateFromMinutes(settings.quietHoursStartMinutes) },
            set: { settings.quietHoursStartMinutes = minutesFromDate($0) }
        )
    }

    private var quietHoursEndBinding: Binding<Date> {
        Binding(
            get: { dateFromMinutes(settings.quietHoursEndMinutes) },
            set: { settings.quietHoursEndMinutes = minutesFromDate($0) }
        )
    }

    private func dateFromMinutes(_ totalMinutes: Int) -> Date {
        let hour = totalMinutes / 60
        let minute = totalMinutes % 60
        let calendar = Calendar.current
        return calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }

    private func minutesFromDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
