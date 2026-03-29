import AppKit
import SwiftUI

/// Borderless session panel must be able to become key so Escape / digit shortcuts reach the app reliably.
private final class BreathingOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

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

        let rootView: AnyView
        switch settings.breathingPresentationStyle {
        case .notch:
            rootView = AnyView(
                NotchOverlayView(
                    viewModel: vm,
                    notchInfo: info,
                    settings: settings,
                    onDismiss: { [weak self] in self?.tearDown(settings: settings) }
                )
            )
        case .fullscreenOverlay:
            rootView = AnyView(
                FullscreenBreathingOverlayView(
                    viewModel: vm,
                    settings: settings,
                    onDismiss: { [weak self] in self?.tearDown(settings: settings) }
                )
            )
        }

        let panel = createPanel(hasNotch: info.hasNotch)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.layer?.backgroundColor = .clear
        hostingView.focusRingType = .none
        panel.contentView = hostingView
        self.panel = panel

        applyPresentationLevel(panel, style: settings.breathingPresentationStyle)

        let windowFrame = panelFrame(for: settings.breathingPresentationStyle, info: info)
        panel.setFrame(windowFrame, display: false)
        panel.alphaValue = 1
        panel.orderFrontRegardless()
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if Self.isEscapeKey(event) {
                self?.dismiss()
                return nil
            }
            if let vm = self?.sessionViewModel,
               vm.postSessionMoodInputReady,
               !vm.statsRecorded,
               let ch = event.charactersIgnoringModifiers?.first,
               let digit = ch.wholeNumberValue,
               (1...3).contains(digit) {
                vm.pendingMoodShortcut = digit
                return nil
            }
            return event
        }
    }

    func dismiss() {
        sessionViewModel?.shouldDismiss = true
    }

    /// Instant cleanup — called by the view after the collapse animation finishes.
    func tearDown(settings: UserSettings) {
        guard let panel else { return }
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        if let vm = sessionViewModel, !vm.statsRecorded {
            if vm.finishedFullPlan {
                settings.recordBreathingSession(
                    actualSeconds: vm.plannedSessionSeconds,
                    countsAsFullSession: true,
                    mood: nil
                )
            } else {
                let elapsed = vm.elapsedSecondsClampedToPlan()
                if elapsed >= 1 {
                    settings.recordBreathingSession(
                        actualSeconds: elapsed,
                        countsAsFullSession: false,
                        mood: nil
                    )
                }
            }
            vm.statsRecorded = true
        }
        sessionViewModel?.stop()
        panel.orderOut(nil)
        self.panel = nil
        self.sessionViewModel = nil
    }

    // MARK: - Panel

    private static func isEscapeKey(_ event: NSEvent) -> Bool {
        if event.keyCode == 53 { return true }
        if event.charactersIgnoringModifiers == "\u{1b}" { return true }
        return false
    }

    private func createPanel(hasNotch: Bool) -> NSPanel {
        let panel = BreathingOverlayPanel(
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

    private func applyPresentationLevel(_ panel: NSPanel, style: BreathingPresentationStyle) {
        switch style {
        case .notch:
            panel.level = .mainMenu + 3
        case .fullscreenOverlay:
            panel.level = .screenSaver
        }
    }

    private func panelFrame(for style: BreathingPresentationStyle, info: NotchInfo) -> NSRect {
        switch style {
        case .notch:
            return oversizedFrame(info: info)
        case .fullscreenOverlay:
            return info.screenFrame
        }
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
