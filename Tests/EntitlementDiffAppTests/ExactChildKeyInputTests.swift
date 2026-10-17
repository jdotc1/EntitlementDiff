import XCTest
import AppKit
import SwiftUI
@testable import EntitlementDiffApp

final class ExactKeyInputTests: XCTestCase {
    @MainActor
    func testNativeEditDeliversExactBytesAndInvalidatesLookup() {
        var input = ExactKeyInput(value: "é")
        var invalidations = 0
        let bridge = ExactKeyField(input: Binding(get: { input }, set: { input = $0 }),
                                        edited: { invalidations += 1 })
        let coordinator = bridge.makeCoordinator()
        let field = NSTextField(string: "e\u{301}")
        coordinator.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
        XCTAssertEqual(Array(input.value.utf8), Array("e\u{301}".utf8))
        XCTAssertEqual(invalidations, 1)
        field.stringValue = ""
        coordinator.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
        XCTAssertEqual(input.value, "")
        XCTAssertEqual(invalidations, 2)
    }

    func testCanonicalEquivalentInputStillInvalidatesResult() {
        XCTAssertNotEqual(ExactKeyInput(value: "é"), ExactKeyInput(value: "e\u{301}"))
        XCTAssertNotEqual(ExactKeyInput(value: " spaced "), ExactKeyInput(value: "spaced"))
        XCTAssertEqual(ExactKeyInput(value: ""), ExactKeyInput(value: ""))
    }
}
