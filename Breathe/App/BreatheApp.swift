import SwiftUI

@main
struct BreatheApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                overlayController: appDelegate.overlayController,
                settings: appDelegate.userSettings
            )
        } label: {
            Label("Breathe", systemImage: "wind")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appDelegate.userSettings)
        }

        Window("Shape Tuner", id: "shape-tuner") {
            ShapeTunerView()
        }
        .defaultSize(width: 700, height: 520)
    }
}
