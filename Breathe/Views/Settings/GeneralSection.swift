import SwiftUI

struct GeneralSection: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            VStack(spacing: 20) {
                SettingsCard(title: "Startup") {
                    HStack {
                        Text("Launch at login")
                            .font(.system(size: 13))
                        Spacer()
                        Toggle("", isOn: $settings.launchAtLogin)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }

                SettingsCard(title: "About") {
                    SettingsRow("Version") {
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 13))
                    }

                    SettingsDivider()

                    SettingsRow("Breathe") {
                        Text("Box breathing for macOS")
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
