import AppKit
import XCTest
import EntitlementDiffCore
import EntitlementDiffModel
@testable import EntitlementDiffApp

@MainActor
final class ViewedScalarCopyTests: XCTestCase {
    private func document(_ text: String) throws -> LeafValueDocument {
        try LeafValueDocument(leaf:XCTUnwrap(InspectorLeaf(.string(text))))
    }
    func testOriginalUnicodeLastSuccessAndBoundedText() throws {
        let doc=try document(String(repeating:"🙂",count:512)+"e\u{301}\u{200B}")
        var nav=StringScalarNavigation();XCTAssertNil(nav.copyText(side:.previous))
        nav.setInput("514");XCTAssertTrue(nav.go(document:doc))
        let text=try XCTUnwrap(nav.copyText(side:.previous)), position=nav.position, revision=nav.revision
        XCTAssertTrue(text.hasPrefix("Previous viewed scalar details\nScalar position: 514 (1-based)\nUTF-8 byte position: 2050 (1-based)\n"))
        XCTAssertTrue(text.contains("U+0301 · \\u{0301}"));XCTAssertTrue(text.contains("UTF-8: CC 81"))
        nav.setInput("1");XCTAssertEqual(nav.copyText(side:.previous),text)
        nav.setInput("999");XCTAssertFalse(nav.go(document:doc));XCTAssertEqual(nav.copyText(side:.previous),text)
        XCTAssertEqual(nav.position,position);XCTAssertEqual(nav.revision,revision)
        nav.setInput("515");XCTAssertTrue(nav.go(document:doc));let invisible=try XCTUnwrap(nav.copyText(side:.previous))
        XCTAssertTrue(invisible.contains("U+200B"));XCTAssertTrue(invisible.contains("E2 80 8B"));XCTAssertFalse(invisible.contains("\u{200B}"))
        XCTAssertLessThan(invisible.utf8.count,StringScalarNavigation.copyByteLimit)
        nav.reset();XCTAssertNil(nav.copyText(side:.previous))
    }
    func testEmojiASCIIEOFEmptyAndIndependentSides() throws {
        var left=StringScalarNavigation(),right=StringScalarNavigation()
        let doc=try document("a🙂")
        left.setInput("1");XCTAssertTrue(left.go(document:doc));XCTAssertTrue(try XCTUnwrap(left.copyText(side:.previous)).contains("UTF-8: 61"))
        left.setInput("2");XCTAssertTrue(left.go(document:doc));let emoji=try XCTUnwrap(left.copyText(side:.previous))
        XCTAssertTrue(emoji.contains("U+1F642"));XCTAssertTrue(emoji.contains("F0 9F 99 82"))
        right.setInput("3");XCTAssertTrue(right.go(document:doc));let eof=try XCTUnwrap(right.copyText(side:.current))
        XCTAssertTrue(eof.hasPrefix("Current viewed scalar details"));XCTAssertTrue(eof.contains("UTF-8 byte position: 6"));XCTAssertTrue(eof.contains("End of string\nUTF-8: EOF"))
        right.setInput("1");XCTAssertTrue(right.go(document:try document("")));XCTAssertTrue(try XCTUnwrap(right.copyText(side:.current)).contains("Scalar position: 1 (1-based)\nUTF-8 byte position: 1"))
        XCTAssertEqual(left.copyText(side:.previous),emoji)
    }
    func testClipboardGuardsAndSearchDifferenceIndependence() async throws {
        let actions=AppActions(model:ComparisonModel(reader:ScalarCopyUnusedReader()))
        let selection=FocusedValueSelection(entitlementKey:"key",pathPreview:"Value",previous:.string("aé"),current:.string("🙂x"));actions.focusedValue=selection
        let difference=FocusedStringDifference(previous:"aé",current:"🙂x");try await XCTUnwrap(difference.find()).value
        let search=FocusedStringSearch(source:"aé");search.setQuery(.init(value:"é"));try await XCTUnwrap(search.find()).value
        let result=difference.copyDetails, revision=difference.revision, match=search.match
        var nav=StringScalarNavigation();nav.setInput("2");XCTAssertTrue(nav.go(document:try document("aé")))
        let clipboard=NSPasteboard.withUniqueName();defer { clipboard.releaseGlobally() }
        actions.copyScalarDetails(nav,side:.previous,selectionID:selection.id,to:clipboard);let copied=clipboard.string(forType:.string)
        XCTAssertEqual(copied,nav.copyText(side:.previous))
        actions.copyScalarDetails(nav,side:.current,selectionID:UUID(),to:clipboard)
        actions.focusedValue=nil;actions.copyScalarDetails(nav,side:.current,selectionID:selection.id,to:clipboard)
        XCTAssertEqual(clipboard.string(forType:.string),copied)
        nav.reset();actions.focusedValue=selection;actions.copyScalarDetails(nav,side:.current,selectionID:selection.id,to:clipboard)
        XCTAssertEqual(clipboard.string(forType:.string),copied);XCTAssertEqual(difference.copyDetails,result);XCTAssertEqual(difference.revision,revision);XCTAssertEqual(search.match,match)
    }
}
private actor ScalarCopyUnusedReader: SnapshotReading {
    func read(at url:URL,architecture:Architecture) async throws -> EntitlementSnapshot { throw CancellationError() }
}
