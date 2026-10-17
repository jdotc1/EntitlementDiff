import XCTest
import AppKit
import SwiftUI
@testable import EntitlementDiffApp

final class ExactChildKeyInputTests: XCTestCase {
    @MainActor
    func testNativeEditDeliversExactBytesAndInvalidatesLookup() {
        var input = ExactChildKeyInput(value: "é")
        var invalidations = 0
        let bridge = ExactChildKeyField(input: Binding(get: { input }, set: { input = $0 }),
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
        XCTAssertNotEqual(ExactChildKeyInput(value: "é"), ExactChildKeyInput(value: "e\u{301}"))
        XCTAssertNotEqual(ExactChildKeyInput(value: " spaced "), ExactChildKeyInput(value: "spaced"))
        XCTAssertEqual(ExactChildKeyInput(value: ""), ExactChildKeyInput(value: ""))
    }
}
