import SwiftUI

/// Animatable shape that draws a notch-like form centered horizontally at the
/// top of its bounding rect, mimicking the physical MacBook notch profile.
///
/// The top corners are SHARP (pointed) where the top edge meets the ear —
/// matching the real notch bezel junction. Below the sharp corner, each ear
/// drops straight down then curves smoothly inward to meet the body.
struct NotchShape: Shape {
    var shapeWidth: CGFloat
    var shapeHeight: CGFloat
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { .init(.init(shapeWidth, shapeHeight), .init(topCornerRadius, bottomCornerRadius)) }
        set {
            shapeWidth = newValue.first.first
            shapeHeight = newValue.first.second
            topCornerRadius = newValue.second.first
            bottomCornerRadius = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let left = cx - shapeWidth / 2
        let right = cx + shapeWidth / 2
        let topR = max(topCornerRadius, 0)
        let botR = max(bottomCornerRadius, 0)
        let bodyL = left + topR
        let bodyR = right - topR

        let straightH = topR * 1.0
        let curveH = topR * 1.44
        let overshoot = (straightH + curveH) * 0.71
        let top = rect.minY - overshoot
        let bottom = rect.minY + shapeHeight

        var p = Path()

        // ── Top edge (flush with bezel) ──
        p.move(to: CGPoint(x: left, y: top))
        p.addLine(to: CGPoint(x: right, y: top))

        // ── Right ear: sharp corner → straight down → curve inward ──
        p.addLine(to: CGPoint(x: right, y: top + straightH))
        p.addCurve(
            to: CGPoint(x: bodyR, y: top + straightH + curveH),
            control1: CGPoint(x: right, y: top + straightH + curveH * 0.80),
            control2: CGPoint(x: bodyR, y: top + straightH + curveH * 0.20)
        )

        // ── Right side ──
        p.addLine(to: CGPoint(x: bodyR, y: bottom - botR))

        // ── Bottom-right corner ──
        p.addCurve(
            to: CGPoint(x: bodyR - botR, y: bottom),
            control1: CGPoint(x: bodyR, y: bottom - botR * 0.44),
            control2: CGPoint(x: bodyR - botR * 0.44, y: bottom)
        )

        // ── Bottom edge ──
        p.addLine(to: CGPoint(x: bodyL + botR, y: bottom))

        // ── Bottom-left corner ──
        p.addCurve(
            to: CGPoint(x: bodyL, y: bottom - botR),
            control1: CGPoint(x: bodyL + botR * 0.44, y: bottom),
            control2: CGPoint(x: bodyL, y: bottom - botR * 0.44)
        )

        // ── Left side ──
        p.addLine(to: CGPoint(x: bodyL, y: top + straightH + curveH))

        // ── Left ear: curve outward → straight up → sharp corner ──
        p.addCurve(
            to: CGPoint(x: left, y: top + straightH),
            control1: CGPoint(x: bodyL, y: top + straightH + curveH * 0.20),
            control2: CGPoint(x: left, y: top + straightH + curveH * 0.80)
        )
        p.addLine(to: CGPoint(x: left, y: top))

        p.closeSubpath()
        return p
    }
}
