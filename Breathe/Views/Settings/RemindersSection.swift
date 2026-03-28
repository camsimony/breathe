import SwiftUI

struct RemindersSection: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            VStack(spacing: 20) {
                SettingsCard(title: "Frequency") {
                    SettingsRow("Remind me") {
                        Picker("", selection: $settings.reminderFrequencyRaw) {
                            ForEach(ReminderFrequency.allCases) { freq in
                                Text(freq.displayName).tag(freq.rawValue)
                            }
                        }
                        .labelsHidden()
                    }
                }

                SettingsCard(title: "Quiet Hours") {
                    HStack {
                        Text("Enable quiet hours")
                            .font(.system(size: 13))
                        Spacer()
                        Toggle("", isOn: $settings.quietHoursEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)

                    if settings.quietHoursEnabled {
                        SettingsDivider()

                        DatePicker(
                            "From",
                            selection: quietHoursStartBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .font(.system(size: 13))
                        .padding(.vertical, 4)

                        SettingsDivider()

                        DatePicker(
                            "Until",
                            selection: quietHoursEndBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .font(.system(size: 13))
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Time Bindings

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
