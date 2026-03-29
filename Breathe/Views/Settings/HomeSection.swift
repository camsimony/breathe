import SwiftUI

struct HomeSection: View {
    @AppStorage("statsTotalSeconds") private var statsTotalSeconds: Double = 0
    @AppStorage("statsWeekSessionCount") private var statsWeekSessionCount: Int = 0
    @AppStorage("statsTotalFullSessions") private var statsTotalFullSessions: Int = 0
    @AppStorage("statsMoodSum") private var statsMoodSum: Int = 0
    @AppStorage("statsMoodCount") private var statsMoodCount: Int = 0

    private var totalMinutesDisplay: Int { Int(statsTotalSeconds / 60) }

    private var averageMoodDisplay: String {
        guard statsMoodCount > 0 else { return "—" }
        let avg = Double(statsMoodSum) / Double(statsMoodCount)
        return String(format: "%.1f / 3", avg)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                homeStatsOverview

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
                        Text("After a full session, you can log mood with 1–3 or the emoji row (optional). Escape skips it.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
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

    private var homeStatsOverview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Overview")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            HStack(alignment: .top, spacing: 20) {
                HomeStatColumn(
                    value: "\(totalMinutesDisplay)",
                    label: "Minutes breathing"
                )
                HomeStatColumn(
                    value: "\(statsWeekSessionCount)",
                    label: "Sessions this week"
                )
                HomeStatColumn(
                    value: averageMoodDisplay,
                    label: "Avg. mood"
                )
                HomeStatColumn(
                    value: "\(statsTotalFullSessions)",
                    label: "Sessions all-time"
                )
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

}

private struct HomeStatColumn: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
