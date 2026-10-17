import AppKit
import SwiftUI
import XCTest
@testable import EntitlementDiffApp

final class ExactKeyFieldCommandTests: XCTestCase {
    @MainActor
    func testRawEditsAndReturnUseCurrentInputAndEscapeCancels() {
        var input = ExactKeyInput(value: "é")
        var feedback = true
        var submitted: [[UInt8]] = []
        var cancelled = false
        let bridge = ExactKeyField(input: Binding(get: { input }, set: { input = $0 }),
                                   placeholder: "Exact entitlement key", initiallyFocused: true,
                                   submit: { submitted.append(Array(input.value.utf8)) },
                                   cancel: { cancelled = true }, edited: { feedback = false })
        let coordinator = bridge.makeCoordinator()
        let field = NSTextField(string: "e\u{301}"), editor = NSTextView()
        coordinator.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
        XCTAssertFalse(feedback)
        XCTAssertTrue(coordinator.control(field, textView: editor, doCommandBy: #selector(NSResponder.insertNewline(_:))))
        XCTAssertEqual(submitted, [Array("e\u{301}".utf8)])
        XCTAssertTrue(coordinator.control(field, textView: editor, doCommandBy: #selector(NSResponder.cancelOperation(_:))))
        XCTAssertTrue(cancelled)
        XCTAssertFalse(coordinator.control(field, textView: editor, doCommandBy: #selector(NSResponder.moveLeft(_:))))
        ExactKeyField.dismantleNSView(field, coordinator: coordinator)
        XCTAssertNil(field.delegate)
    }

    @MainActor
    func testChildFieldKeepsDefaultCommandHandling() {
        var input = ExactKeyInput()
        let coordinator = ExactKeyField(input: Binding(get: { input }, set: { input = $0 }), edited: {}).makeCoordinator()
        let field = NSTextField(), editor = NSTextView()
        XCTAssertFalse(coordinator.control(field, textView: editor, doCommandBy: #selector(NSResponder.insertNewline(_:))))
        XCTAssertFalse(coordinator.control(field, textView: editor, doCommandBy: #selector(NSResponder.cancelOperation(_:))))
    }
}
