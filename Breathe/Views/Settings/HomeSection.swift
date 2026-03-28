import SwiftUI

struct HomeSection: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsCard(title: "Breathe") {
                    Text("Box breathing from the menu bar. Start a session when you need to reset, or let reminders nudge you during the day.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                SettingsCard(title: "Tips") {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Press ⌘B in the menu to start breathing quickly.", systemImage: "command")
                            .font(.system(size: 13))
                            .foregroundStyle(.primary)
                            .labelStyle(.titleAndIcon)
                        Text("Tweak timing under Breathing, session length under Session, and nudges under Reminders.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
