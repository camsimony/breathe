import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    let overlayController: OverlayWindowController
    let settings: UserSettings

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "lungs.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                Text("Breathe")
                    .font(.headline)
            }
            .padding(.top, 4)

            Divider()

            // Quick start
            Button {
                overlayController.show(settings: settings)
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                    Text("Start Breathing")
                }
                .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .keyboardShortcut("b", modifiers: [.command])

            // Current preset info
            HStack {
                Text("Preset:")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(settings.currentPreset.name)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(settings.currentPreset.inhale))s cycle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            Divider()

            // Settings
            SettingsLink {
                HStack {
                    Image(systemName: "gear")
                        .font(.system(size: 11))
                    Text("Settings")
                    Spacer()
                    Text("\u{2318},")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Button {
                openWindow(id: "shape-tuner")
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11))
                    Text("Shape Tuner")
                    Spacer()
                }
            }

            Divider()

            Button("Quit Breathe") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
        .padding(10)
        .frame(width: 220)
    }
}
