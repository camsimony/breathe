import SwiftUI

struct GeneralSection: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }

            Section("About") {
                LabeledContent("Version") {
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Breathe") {
                    Text("Box breathing for macOS")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
