import SwiftUI

struct SessionSection: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            VStack(spacing: 20) {
                SettingsCard(title: "Duration Mode") {
                    HStack {
                        Text("Use cycle count instead of time")
                            .font(.system(size: 13))
                        Spacer()
                        Toggle("", isOn: $settings.useSessionCycles)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }

                if settings.useSessionCycles {
                    SettingsCard(title: "Cycles") {
                        Stepper(
                            "\(settings.sessionCycleCount) cycles",
                            value: $settings.sessionCycleCount,
                            in: 1...20
                        )
                        .font(.system(size: 13))
                        .padding(.vertical, 4)

                        SettingsDivider()

                        SettingsRow("Estimated Duration") {
                            let duration = Int(settings.sessionDurationSeconds)
                            let min = duration / 60
                            let sec = duration % 60
                            Text(sec > 0 ? "\(min)m \(sec)s" : "\(min)m")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 13))
                        }
                    }
                } else {
                    SettingsCard(title: "Duration") {
                        Stepper(
                            "\(settings.sessionDurationMinutes) minutes",
                            value: $settings.sessionDurationMinutes,
                            in: 1...30
                        )
                        .font(.system(size: 13))
                        .padding(.vertical, 4)

                        SettingsDivider()

                        SettingsRow("Estimated Cycles") {
                            let cycles = Int(settings.sessionDurationSeconds / settings.currentPreset.totalCycleDuration)
                            Text("~\(cycles) cycles")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 13))
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
