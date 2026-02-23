import AppKit

struct NotchInfo {
    let hasNotch: Bool
    let notchRect: NSRect?
    let notchWidth: CGFloat
    let notchHeight: CGFloat
    let screenFrame: NSRect
    let menuBarHeight: CGFloat
}

final class NotchDetector {

    func detect() -> NotchInfo {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let menuBarHeight: CGFloat = NSApp.mainMenu?.menuBarHeight ?? 24

        var notchWidth: CGFloat = 220
        var notchHeight: CGFloat = 38

        if let leftArea = screen.auxiliaryTopLeftArea,
           let rightArea = screen.auxiliaryTopRightArea {
            notchWidth = screen.frame.width - leftArea.width - rightArea.width + 4
            notchHeight = screen.safeAreaInsets.top
        }

        return NotchInfo(
            hasNotch: screen.hasNotch,
            notchRect: screen.notchRect,
            notchWidth: notchWidth,
            notchHeight: notchHeight,
            screenFrame: screen.frame,
            menuBarHeight: menuBarHeight
        )
    }
}
