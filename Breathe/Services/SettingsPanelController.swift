import AppKit
import SwiftUI

@MainActor
final class SettingsPanelController: NSObject, NSWindowDelegate {
    private let settings: UserSettings
    private var panel: NSPanel?

    /// Shift traffic lights right so they line up with the sidebar icon column (titlebar accessory does not move them with a unified toolbar).
    private static let trafficLightLeadingInset: CGFloat = 11

    private var didShiftTrafficLights = false

    init(settings: UserSettings) {
        self.settings = settings
    }

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel

        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        scheduleTrafficLightLeadingShift(for: panel)
    }

    func windowWillClose(_ notification: Notification) {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let frame = NSRect(x: 0, y: 0, width: 680, height: 380)
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )

        panel.title = ""
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.delegate = self
        panel.minSize = NSSize(width: 680, height: 380)
        panel.maxSize = NSSize(width: 680, height: 10_000)
        if #available(macOS 15.0, *) {
            panel.titlebarSeparatorStyle = .none
        }

        let toolbar = NSToolbar(identifier: "settingsToolbar")
        toolbar.showsBaselineSeparator = false
        panel.toolbar = toolbar
        panel.toolbarStyle = .unifiedCompact

        let visualEffect = NSVisualEffectView(frame: frame)
        visualEffect.material = .underWindowBackground
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.masksToBounds = true

        let hostingView = NSHostingView(
            rootView: SettingsView()
                .environment(settings)
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        visualEffect.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])

        panel.contentView = visualEffect
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.center()

        return panel
    }

    /// Unified toolbar lays out traffic lights after the first frame; retry on later run-loop turns until we see real frames.
    private func scheduleTrafficLightLeadingShift(for panel: NSPanel) {
        func attempt(_ pass: Int) {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                panel.layoutIfNeeded()
                if self.shiftTrafficLightsRightIfNeeded(in: panel) {
                    return
                }
                if pass < 8 {
                    attempt(pass + 1)
                }
            }
        }
        attempt(0)
    }

    @discardableResult
    private func shiftTrafficLightsRightIfNeeded(in panel: NSPanel) -> Bool {
        guard !didShiftTrafficLights else { return true }
        guard let close = panel.standardWindowButton(.closeButton), close.frame.width > 0 else { return false }

        let inset = Self.trafficLightLeadingInset
        for type in [NSWindow.ButtonType.closeButton, NSWindow.ButtonType.miniaturizeButton] {
            guard let btn = panel.standardWindowButton(type) else { continue }
            var f = btn.frame
            f.origin.x += inset
            btn.frame = f
        }
        didShiftTrafficLights = true
        return true
    }
}
