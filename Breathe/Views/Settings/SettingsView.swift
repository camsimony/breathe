import SwiftUI

struct SettingsView: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        TabView {
            TimingPresetsSection()
                .tabItem { Label("Breathing", systemImage: "wind") }

            SessionSection()
                .tabItem { Label("Session", systemImage: "timer") }

            RemindersSection()
                .tabItem { Label("Reminders", systemImage: "bell") }

            GeneralSection()
                .tabItem { Label("General", systemImage: "gear") }
        }
        .frame(width: 440, height: 300)
    }
}
