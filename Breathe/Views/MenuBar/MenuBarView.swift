import SwiftUI

struct MenuBarView: View {
    let overlayController: OverlayWindowController
    let settings: UserSettings
    let onOpenSettings: () -> Void

    var body: some View {
        Button(action: startBreathing) {
            Label("Start Breathing", systemImage: "wind")
        }
        .keyboardShortcut("b", modifiers: [.command])

        Divider()

        Button(action: openSettings) {
            Label("Settings…", systemImage: "gear")
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        Text("Version 1.0.0")

        Button(action: quit) {
            Label("Quit Breathe", systemImage: "xmark.square")
        }
        .keyboardShortcut("q", modifiers: [.command])
    }

    // MARK: - Actions

    private func startBreathing() {
        overlayController.show(settings: settings)
    }

    private func openSettings() {
        onOpenSettings()
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
