import AppKit
import SwiftUI

@MainActor
final class SettingsPanelController: NSObject, NSWindowDelegate {
    private let settings: UserSettings
    private var panel: NSPanel?

    private static let preferredContentWidth: CGFloat = 750
    private static let preferredMinHeight: CGFloat = 380

    /// Shift traffic lights right so they line up with the sidebar icon column (titlebar accessory does not move them with a unified toolbar).
    private static let trafficLightLeadingInset: CGFloat = 11

    private var didShiftTrafficLights = false

    init(settings: UserSettings) {
        self.settings = settings
    }

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel

        normalizePanelContentWidth(panel)

        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        scheduleTrafficLightLeadingShift(for: panel)
    }

    func windowWillClose(_ notification: Notification) {
        panel?.orderOut(nil)
    }

    /// Panel is reused for the app lifetime; resize when `preferredContentWidth` changes or after an older build created a narrower window.
    private func normalizePanelContentWidth(_ panel: NSWindow) {
        var frame = panel.frame
        let target = Self.preferredContentWidth
        guard abs(frame.size.width - target) > 0.5 else { return }
        let midX = frame.midX
        frame.size.width = target
        frame.origin.x = midX - frame.width / 2
        panel.setFrame(frame, display: true)
    }

    private func makePanel() -> NSPanel {
        let w = Self.preferredContentWidth
        let h = Self.preferredMinHeight
        let frame = NSRect(x: 0, y: 0, width: w, height: h)
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
        panel.minSize = NSSize(width: w, height: h)
        panel.maxSize = NSSize(width: w, height: 10_000)
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
