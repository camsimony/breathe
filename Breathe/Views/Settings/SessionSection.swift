import SwiftUI

struct SessionSection: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Duration Mode") {
                Toggle("Use cycle count instead of time", isOn: $settings.useSessionCycles)
            }

            if settings.useSessionCycles {
                Section("Cycles") {
                    Stepper(
                        "\(settings.sessionCycleCount) cycles",
                        value: $settings.sessionCycleCount,
                        in: 1...20
                    )

                    LabeledContent("Estimated Duration") {
                        let duration = Int(settings.sessionDurationSeconds)
                        let min = duration / 60
                        let sec = duration % 60
                        Text(sec > 0 ? "\(min)m \(sec)s" : "\(min)m")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Section("Duration") {
                    Stepper(
                        "\(settings.sessionDurationMinutes) minutes",
                        value: $settings.sessionDurationMinutes,
                        in: 1...30
                    )

                    LabeledContent("Estimated Cycles") {
                        let cycles = Int(settings.sessionDurationSeconds / settings.currentPreset.totalCycleDuration)
                        Text("~\(cycles) cycles")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
