import SwiftUI

@main
struct BreatheApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                overlayController: appDelegate.overlayController,
                settings: appDelegate.userSettings,
                onOpenSettings: appDelegate.showSettings
            )
        } label: {
            Label("Breathe", systemImage: "wind")
        }
        .menuBarExtraStyle(.menu)

        Window("Shape Tuner", id: "shape-tuner") {
            ShapeTunerView()
        }
        .defaultSize(width: 700, height: 520)
    }
}
