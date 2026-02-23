import AppKit
import SwiftUI

@Observable
final class OverlayWindowController {
    private var panel: NSPanel?
    private var sessionViewModel: BreathingSessionViewModel?
    private let notchDetector = NotchDetector()
    private var keyMonitor: Any?

    var isShowingSession: Bool { panel != nil }

    func show(settings: UserSettings) {
        if panel != nil {
            sessionViewModel?.shouldDismiss = true
            return
        }

        let info = notchDetector.detect()
        let vm = BreathingSessionViewModel(settings: settings)
        self.sessionViewModel = vm

        vm.onSessionComplete = { [weak self] in
            DispatchQueue.main.async {
                self?.sessionViewModel?.shouldDismiss = true
            }
        }

        let rootView = NotchOverlayView(
            viewModel: vm,
            notchInfo: info,
            onDismiss: { [weak self] in self?.tearDown() }
        )

        let panel = createPanel(hasNotch: info.hasNotch)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.layer?.backgroundColor = .clear
        panel.contentView = hostingView
        self.panel = panel

        let windowFrame = oversizedFrame(info: info)
        panel.setFrame(windowFrame, display: false)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.dismiss()
                return nil
            }
            return event
        }
    }

    func dismiss() {
        sessionViewModel?.shouldDismiss = true
    }

    /// Instant cleanup — called by the view after the collapse animation finishes.
    func tearDown() {
        guard let panel else { return }
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        sessionViewModel?.stop()
        panel.orderOut(nil)
        self.panel = nil
        self.sessionViewModel = nil
    }

    // MARK: - Panel

    private func createPanel(hasNotch: Bool) -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        panel.isFloatingPanel = true
        panel.level = .mainMenu + 3
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none

        return panel
    }

    /// Oversized window centered at screen top. Content is masked inside.
    private func oversizedFrame(info: NotchInfo) -> NSRect {
        let screen = info.screenFrame
        let width = screen.width / 2
        let height = screen.height / 2

        return NSRect(
            x: screen.midX - width / 2,
            y: screen.maxY - height,
            width: width,
            height: height
        )
    }
}
