import AppKit
import XCTest
import EntitlementDiffCore
import EntitlementDiffModel
@testable import EntitlementDiffApp

@MainActor
final class CurrentDifferenceDetailsTests: XCTestCase {
    func testStringCurrentSelectionExactUnicodeEOFAndReset() async throws {
        let model = FocusedStringDifference(previous: "aéZ", current: "🙂\u{200B}Yx")
        XCTAssertNil(model.copyDetails)
        try await XCTUnwrap(model.find()).value
        for _ in 0..<3 { try await XCTUnwrap(model.next()).value }
        XCTAssertTrue(try XCTUnwrap(model.copyDetails).contains("Previous: End of string"))
        model.setJumpInput("2"); model.jumpToFound()
        let text = try XCTUnwrap(model.copyDetails), revision = model.revision
        XCTAssertTrue(text.contains("String difference 2\n"))
        XCTAssertTrue(text.contains("Previous UTF-8 byte: 2"))
        XCTAssertTrue(text.contains("Current UTF-8 byte: 5"))
        XCTAssertTrue(text.contains("U+00E9 · \\u{00E9}"))
        XCTAssertTrue(text.contains("Current UTF-8: E2 80 8B"))
        XCTAssertFalse(text.contains("\u{200B}"))
        model.setJumpInput("999"); model.jumpToFound()
        XCTAssertEqual(model.copyDetails, text); XCTAssertEqual(model.revision, revision)
        model.previousFound(); XCTAssertTrue(try XCTUnwrap(model.copyDetails).contains("U+1F642"))
        model.cancel(); XCTAssertNil(model.copyDetails)
    }
    func testClipboardRejectsStaleDismissedAndOversizedPayloads() throws {
        let actions = AppActions(model: ComparisonModel(reader: DetailsUnusedReader()))
        let selection = FocusedValueSelection(entitlementKey: "key", pathPreview: "Value", previous: .string("a"), current: .string("b"))
        actions.focusedValue = selection
        let clipboard = NSPasteboard.withUniqueName()
        defer { clipboard.releaseGlobally() }
        actions.copyDifferenceDetails("U+00E9 UTF-8: C3 A9", selectionID: selection.id, to: clipboard)
        XCTAssertEqual(clipboard.string(forType: .string), "U+00E9 UTF-8: C3 A9")
        actions.copyDifferenceDetails("stale", selectionID: UUID(), to: clipboard)
        actions.copyDifferenceDetails(String(repeating: "x", count: 2049), selectionID: selection.id, to: clipboard)
        actions.copyDifferenceDetails(nil, selectionID: selection.id, to: clipboard)
        XCTAssertEqual(clipboard.string(forType: .string), "U+00E9 UTF-8: C3 A9")
        actions.focusedValue = nil
        actions.copyDifferenceDetails("dismissed", selectionID: selection.id, to: clipboard)
        XCTAssertEqual(clipboard.string(forType: .string), "U+00E9 UTF-8: C3 A9")
    }
    func testPausedComparisonCannotCopyOldResult() async throws {
        let model = FocusedStringDifference(previous: "a" + String(repeating: "x", count: 40000), current: "b" + String(repeating: "x", count: 40000))
        try await XCTUnwrap(model.find()).value
        XCTAssertNotNil(model.copyDetails)
        let task = try XCTUnwrap(model.next())
        XCTAssertNil(model.copyDetails)
        await task.value
        XCTAssertEqual(model.phase, .paused); XCTAssertNil(model.copyDetails)
    }
    func testDataContextBoundEOFAndSelection() async throws {
        let model = FocusedDataDifference(previous: Data([0,255]), current: Data([128,1,2]))
        try await XCTUnwrap(model.find()).value
        try await XCTUnwrap(model.next()).value
        let text = try XCTUnwrap(model.copyDetails)
        XCTAssertTrue(text.contains("Data difference 2\n")); XCTAssertTrue(text.contains("00 [FF]")); XCTAssertTrue(text.contains("80 [01] 02"))
        try await XCTUnwrap(model.next()).value
        XCTAssertTrue(try XCTUnwrap(model.copyDetails).contains("[EOF]"))
        model.setJumpInput("2"); model.jumpToFound(); XCTAssertEqual(model.copyDetails,text)
        model.cancel(); XCTAssertNil(model.copyDetails)
        let large = FocusedDataDifference(previous: Data(repeating: 0,count: 100000), current: Data(repeating: 255,count: 100000))
        try await XCTUnwrap(large.find()).value
        XCTAssertLessThan(try XCTUnwrap(large.copyDetails).utf8.count,CurrentDifferenceDetails.byteLimit)
    }
}

private actor DetailsUnusedReader: SnapshotReading {
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot { throw CancellationError() }
}
