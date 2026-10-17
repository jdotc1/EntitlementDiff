import AppKit
import XCTest
import EntitlementDiffCore
import EntitlementDiffModel
@testable import EntitlementDiffApp

@MainActor
final class ViewedByteContextCopyTests: XCTestCase {
    func testLastSuccessfulPositionExactSlicedBytesAndPendingInvalidInput() throws {
        var nav = DataByteNavigation()
        XCTAssertNil(nav.copyText(side: .previous))
        let data = Data([99,0,128,255,88])[1..<4]
        nav.setInput("2"); XCTAssertTrue(nav.go(data: data))
        let saved = try XCTUnwrap(nav.copyText(side: .previous))
        XCTAssertEqual(saved, "Previous viewed byte context\nByte position: 2 (1-based)\nBytes 1–3 · brackets mark byte 2\n00 [80] FF\nBrackets mark the viewed byte or EOF.\n")
        nav.setInput("3"); XCTAssertEqual(nav.copyText(side: .previous),saved)
        nav.setInput("999"); XCTAssertFalse(nav.go(data: data)); XCTAssertEqual(nav.copyText(side: .previous),saved)
        nav.reset(); XCTAssertNil(nav.copyText(side: .previous))
    }
    func testEOFEmptyAndBoundedIndependentSides() throws {
        var left = DataByteNavigation(), right = DataByteNavigation()
        let data = Data(repeating:255,count:100000)
        left.setInput("50000"); XCTAssertTrue(left.go(data: data))
        right.setInput("100001"); XCTAssertTrue(right.go(data: data))
        let a = try XCTUnwrap(left.copyText(side:.previous)), b = try XCTUnwrap(right.copyText(side:.current))
        XCTAssertTrue(a.contains("Byte position: 50000")); XCTAssertTrue(a.contains("[FF]"))
        XCTAssertTrue(b.hasPrefix("Current viewed byte context")); XCTAssertTrue(b.contains("EOF at byte 100001")); XCTAssertTrue(b.contains("[EOF]"))
        XCTAssertLessThan(a.utf8.count,DataByteNavigation.copyByteLimit); XCTAssertLessThan(b.utf8.count,DataByteNavigation.copyByteLimit)
        right.setInput("1"); XCTAssertTrue(right.go(data:Data()))
        XCTAssertTrue(try XCTUnwrap(right.copyText(side:.current)).contains("Empty data · EOF at byte 1\n[EOF]"))
        XCTAssertEqual(left.copyText(side:.previous),a)
    }
    func testClipboardSelectionGuardAndDifferenceIndependence() async throws {
        let actions = AppActions(model: ComparisonModel(reader: ByteCopyUnusedReader()))
        let selection = FocusedValueSelection(entitlementKey:"key",pathPreview:"Value",previous:.data(Data([0,128,255])),current:.data(Data([9,8,7])))
        actions.focusedValue = selection
        let difference = FocusedDataDifference(previous:Data([0,128,255]),current:Data([9,8,7]))
        try await XCTUnwrap(difference.find()).value
        let position = difference.position, revision = difference.revision, details = difference.copyDetails
        var nav = DataByteNavigation(); nav.setInput("3"); XCTAssertTrue(nav.go(data:Data([0,128,255])))
        let clipboard = NSPasteboard.withUniqueName(); defer { clipboard.releaseGlobally() }
        actions.copyByteContext(nav,side:.previous,selectionID:selection.id,to:clipboard)
        let copied = clipboard.string(forType:.string)
        XCTAssertEqual(copied,nav.copyText(side:.previous))
        actions.copyByteContext(nav,side:.current,selectionID:UUID(),to:clipboard)
        actions.focusedValue = nil
        actions.copyByteContext(nav,side:.current,selectionID:selection.id,to:clipboard)
        XCTAssertEqual(clipboard.string(forType:.string),copied)
        XCTAssertEqual(difference.position,position); XCTAssertEqual(difference.revision,revision); XCTAssertEqual(difference.copyDetails,details)
        nav.reset(); actions.focusedValue = selection
        actions.copyByteContext(nav,side:.current,selectionID:selection.id,to:clipboard)
        XCTAssertEqual(clipboard.string(forType:.string),copied)
    }
}
private actor ByteCopyUnusedReader: SnapshotReading {
    func read(at url:URL,architecture:Architecture) async throws -> EntitlementSnapshot { throw CancellationError() }
}
