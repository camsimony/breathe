import SwiftUI

struct CustomizeSection: View {
    @Environment(\.colorScheme) private var colorScheme

    /// Mirrors `UserSettings.breathingPresentationStyle` but lives here so the row updates — the stored key uses `@ObservationIgnored` on `UserSettings`, which does not trigger observation.
    @AppStorage("breathingPresentationStyle") private var presentationStyleRaw: String = BreathingPresentationStyle.notch.rawValue

    private var selectedPresentationStyle: BreathingPresentationStyle {
        BreathingPresentationStyle(rawValue: presentationStyleRaw) ?? .notch
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsCard(title: nil) {
                    HStack(alignment: .top, spacing: 18) {
                        Text("Style")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                            .frame(width: 48, alignment: .leading)

                        HStack(spacing: 14) {
                            ForEach(BreathingPresentationStyle.allCases) { style in
                                BreathingStyleToggleButton(
                                    style: style,
                                    selected: selectedPresentationStyle == style
                                ) {
                                    presentationStyleRaw = style.rawValue
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                SettingsCard(title: "Coming soon") {
                    Text("More visual options will land here.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Style toggle (Superwhisper-style)

/// No opacity / scale change while the mouse is down (avoids the default “dim while pressed” feel).
private struct StyleTogglePressNeutralButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

private struct BreathingStyleToggleButton: View {
    let style: BreathingPresentationStyle
    let selected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// design-eng: user-initiated UI → ease-out, ~150–250ms; skip motion when reduced motion is on.
    private var selectionAnimation: Animation {
        reduceMotion ? .linear(duration: 0.001) : .easeOut(duration: 0.2)
    }

    private let previewWidth: CGFloat = 90
    private let previewHeight: CGFloat = 64
    private let ringInset: CGFloat = 5
    private let selectionStroke: CGFloat = 2.5
    private let innerCorner: CGFloat = 10
    private var outerCorner: CGFloat { innerCorner + ringInset }

    /// Semi-transparent black scrim (same idea as before), stepped down a notch so it’s not as heavy.
    private var innerCardFill: Color {
        switch (colorScheme == .dark, selected) {
        case (true, false):
            return Color.black.opacity(0.36)
        case (true, true):
            return Color.black.opacity(0.26)
        case (false, false):
            return Color.black.opacity(0.04)
        case (false, true):
            return Color.black.opacity(0.065)
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: innerCorner)
                        .fill(innerCardFill)

                    Group {
                        switch style {
                        case .notch: NotchStylePreviewIcon()
                        case .fullscreenOverlay: OverlayStylePreviewIcon()
                        }
                    }
                    .padding(11)
                }
                .frame(width: previewWidth, height: previewHeight)
                .clipShape(RoundedRectangle(cornerRadius: innerCorner))
                .padding(ringInset)
                .overlay(
                    RoundedRectangle(cornerRadius: outerCorner)
                        .strokeBorder(Color.accentColor, lineWidth: selectionStroke)
                        .opacity(selected ? 1 : 0)
                )

                // design-eng: avoid font-weight jump between states; use color only.
                Text(style.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(selected ? Color.primary : Color.secondary)
            }
            .animation(selectionAnimation, value: selected)
        }
        .buttonStyle(StyleTogglePressNeutralButtonStyle())
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

// MARK: - Style preview thumbnails

private struct NotchStylePreviewIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.black.opacity(0.92))
            Capsule()
                .fill(Color.white.opacity(0.36))
                .frame(width: 28, height: 5)
                .offset(y: -14)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.48))
                .frame(width: 36, height: 7)
                .offset(y: 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OverlayStylePreviewIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.5))
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.white.opacity(0.42), lineWidth: 1.2)
                .frame(width: 32, height: 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
