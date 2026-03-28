import SwiftUI

struct TimingPresetsSection: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            VStack(spacing: 20) {
                SettingsCard {
                    SettingsRow("Preset") {
                        Picker("", selection: $settings.selectedPresetId) {
                            ForEach(BreathingPreset.allPresets) { preset in
                                Text("\(preset.name) (\(Int(preset.inhale))s each)")
                                    .tag(preset.id)
                            }
                            Divider()
                            Text("Custom").tag("custom")
                        }
                        .labelsHidden()
                    }
                }

                if settings.selectedPresetId == "custom" {
                    SettingsCard(title: "Custom Timing") {
                        HStack {
                            Text("Inhale")
                                .font(.system(size: 13))
                            Slider(value: $settings.customInhale, in: 2...10, step: 1)
                            Text("\(Int(settings.customInhale))s")
                                .frame(width: 30, alignment: .trailing)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 4)
                        SettingsDivider()
                        HStack {
                            Text("Hold In")
                                .font(.system(size: 13))
                            Slider(value: $settings.customHoldIn, in: 2...10, step: 1)
                            Text("\(Int(settings.customHoldIn))s")
                                .frame(width: 30, alignment: .trailing)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 4)
                        SettingsDivider()
                        HStack {
                            Text("Exhale")
                                .font(.system(size: 13))
                            Slider(value: $settings.customExhale, in: 2...10, step: 1)
                            Text("\(Int(settings.customExhale))s")
                                .frame(width: 30, alignment: .trailing)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 4)
                        SettingsDivider()
                        HStack {
                            Text("Hold Out")
                                .font(.system(size: 13))
                            Slider(value: $settings.customHoldOut, in: 2...10, step: 1)
                            Text("\(Int(settings.customHoldOut))s")
                                .frame(width: 30, alignment: .trailing)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 4)
                    }
                }

                SettingsCard {
                    let preset = settings.currentPreset
                    SettingsRow("Cycle Duration") {
                        Text("\(Int(preset.totalCycleDuration))s per cycle")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 13))
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
