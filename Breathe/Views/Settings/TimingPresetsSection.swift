import SwiftUI

struct TimingPresetsSection: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Picker("Preset", selection: $settings.selectedPresetId) {
                ForEach(BreathingPreset.allPresets) { preset in
                    Text("\(preset.name) (\(Int(preset.inhale))s each)")
                        .tag(preset.id)
                }
                Divider()
                Text("Custom").tag("custom")
            }

            if settings.selectedPresetId == "custom" {
                Section("Custom Timing") {
                    HStack {
                        Text("Inhale")
                        Slider(value: $settings.customInhale, in: 2...10, step: 1)
                        Text("\(Int(settings.customInhale))s")
                            .frame(width: 30, alignment: .trailing)
                            .monospacedDigit()
                    }

                    HStack {
                        Text("Hold In")
                        Slider(value: $settings.customHoldIn, in: 2...10, step: 1)
                        Text("\(Int(settings.customHoldIn))s")
                            .frame(width: 30, alignment: .trailing)
                            .monospacedDigit()
                    }

                    HStack {
                        Text("Exhale")
                        Slider(value: $settings.customExhale, in: 2...10, step: 1)
                        Text("\(Int(settings.customExhale))s")
                            .frame(width: 30, alignment: .trailing)
                            .monospacedDigit()
                    }

                    HStack {
                        Text("Hold Out")
                        Slider(value: $settings.customHoldOut, in: 2...10, step: 1)
                        Text("\(Int(settings.customHoldOut))s")
                            .frame(width: 30, alignment: .trailing)
                            .monospacedDigit()
                    }
                }
            }

            Section {
                let preset = settings.currentPreset
                LabeledContent("Cycle Duration") {
                    Text("\(Int(preset.totalCycleDuration))s per cycle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
