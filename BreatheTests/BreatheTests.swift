import XCTest

@testable import Breathe

final class BreatheTests: XCTestCase {
    func testBreathingPhaseAdvances() {
        XCTAssertEqual(BreathingPhase.inhale.next, .holdIn)
        XCTAssertEqual(BreathingPhase.holdIn.next, .exhale)
        XCTAssertEqual(BreathingPhase.exhale.next, .holdOut)
        XCTAssertEqual(BreathingPhase.holdOut.next, .inhale)
    }

    func testBreathingPhaseLabels() {
        XCTAssertEqual(BreathingPhase.inhale.label, "Inhale")
        XCTAssertEqual(BreathingPhase.exhale.label, "Exhale")
        XCTAssertEqual(BreathingPhase.holdIn.label, "Hold")
        XCTAssertEqual(BreathingPhase.holdOut.label, "Hold")
    }
}
