import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case home
    case customize
    case breathing
    case session
    case reminders
    case general

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home: "Home"
        case .customize: "Customize"
        case .breathing: "Breathing"
        case .session: "Session"
        case .reminders: "Reminders"
        case .general: "General"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .customize: "slider.horizontal.3"
        case .breathing: "lungs.fill"
        case .session: "stopwatch.fill"
        case .reminders: "bell.fill"
        case .general: "gearshape.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .home: .blue
        case .customize: .purple
        case .breathing: .teal
        case .session: .orange
        case .reminders: .yellow
        case .general: .gray
        }
    }
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .home

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05)

            HStack(alignment: .top, spacing: 0) {
                SettingsSidebar(selectedTab: $selectedTab)
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                SettingsDetail(tab: selectedTab)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sidebar

private struct SettingsSidebar: View {
    @Binding var selectedTab: SettingsTab

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(SettingsTab.allCases) { tab in
                    SidebarRow(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        action: { selectedTab = tab }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)

            Spacer()

            HStack(spacing: 6) {
                Text("Breathe")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("v1.0.0")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .padding(.top, 14)
        .frame(width: 180)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct SidebarRow: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let badgeSize: CGFloat = 20

    /// Short, even timing so the highlight doesn’t “coast” after tap (ease-out’s tail felt sluggish here).
    private var selectionAnimation: Animation {
        reduceMotion ? .linear(duration: 0.001) : .linear(duration: 0.11)
    }

    private var selectionBackground: Color {
        if colorScheme == .dark {
            Color.white.opacity(0.16)
        } else {
            Color.black.opacity(0.07)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(tab.iconColor.gradient)
                    .frame(width: badgeSize, height: badgeSize)
                    .overlay {
                        Image(systemName: tab.icon)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white)
                            .symbolRenderingMode(.monochrome)
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.1),
                        radius: 0.75,
                        x: 0,
                        y: 1
                    )
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.12 : 0.05),
                        radius: 3,
                        x: 0,
                        y: 2
                    )

                Text(tab.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? selectionBackground : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .animation(selectionAnimation, value: isSelected)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Detail

private struct SettingsDetail: View {
    let tab: SettingsTab

    var body: some View {
        Group {
            switch tab {
            case .home: HomeSection()
            case .customize: CustomizeSection()
            case .breathing: TimingPresetsSection()
            case .session: SessionSection()
            case .reminders: RemindersSection()
            case .general: GeneralSection()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
