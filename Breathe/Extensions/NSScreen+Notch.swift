import AppKit

extension NSScreen {

    /// Whether this screen has a camera housing (notch).
    var hasNotch: Bool {
        safeAreaInsets.top > 0
    }

    /// The rectangle of the notch in screen coordinates.
    /// Returns nil if no notch is present.
    var notchRect: NSRect? {
        guard hasNotch else { return nil }
        guard let leftArea = auxiliaryTopLeftArea,
              let rightArea = auxiliaryTopRightArea else { return nil }

        let notchX = leftArea.maxX
        let notchWidth = rightArea.minX - leftArea.maxX
        let notchHeight = safeAreaInsets.top
        let notchY = frame.maxY - notchHeight

        return NSRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)
    }

    /// Center-top point of the screen.
    var topCenter: NSPoint {
        NSPoint(x: frame.midX, y: frame.maxY)
    }
}
