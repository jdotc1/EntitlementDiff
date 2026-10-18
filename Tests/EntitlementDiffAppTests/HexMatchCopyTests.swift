import AppKit
import XCTest
import EntitlementDiffCore
import EntitlementDiffModel
@testable import EntitlementDiffApp

@MainActor final class HexMatchCopyTests: XCTestCase {
    func testExactOriginalSlicedBytesAndCompleteLongMatch() async throws {
        let search=FocusedHexSearch(source:Data([9,0,128,255,8])[1..<4]);search.setQuery("00 80 FF")
        XCTAssertNil(search.copyText(side:.previous));try await XCTUnwrap(search.find()).value
        XCTAssertEqual(search.copyText(side:.previous),"Previous hex match details\nByte range: 1–3 (1-based, inclusive)\nMatch length: 3 bytes\nMatched bytes: 00 80 FF\nContext before (up to 8 bytes): \nContext after (up to 8 bytes): \n")
        let bytes=Data((0..<128).map(UInt8.init)),long=FocusedHexSearch(source:Data([255])+bytes+Data([128]))
        long.setQuery(bytes.map { String(format:"%02X",$0) }.joined(separator:" "));try await XCTUnwrap(long.find()).value
        let copy=try XCTUnwrap(long.copyText(side:.current))
        XCTAssertTrue(copy.contains("Byte range: 2–129"));XCTAssertTrue(copy.contains("Match length: 128 bytes"))
        XCTAssertTrue(copy.contains("Matched bytes: "+bytes.map { String(format:"%02X",$0) }.joined(separator:" ")))
        XCTAssertFalse(copy.contains("…"));XCTAssertLessThanOrEqual(copy.utf8.count,FocusedHexSearch.copyByteLimit)
        XCTAssertTrue(copy.contains("Context before (up to 8 bytes): FF"));XCTAssertTrue(copy.contains("Context after (up to 8 bytes): 80"))
    }
    func testCopyPreservesDirectionCursorAndCompletedMatch() async throws {
        let search=FocusedHexSearch(source:Data([0,128,255,1,0,128,255]));search.setQuery("0080FF")
        try await XCTUnwrap(search.find()).value;try await XCTUnwrap(search.advance()).value
        let revision=search.revision,context=search.context
        XCTAssertTrue(try XCTUnwrap(search.copyText(side:.previous)).contains("Byte range: 5–7"))
        XCTAssertEqual(search.revision,revision);XCTAssertEqual(search.context,context)
        try await XCTUnwrap(search.advance(direction:.backward)).value
        let first=search.copyText(side:.previous);XCTAssertTrue(try XCTUnwrap(first).contains("Byte range: 1–3"))
        try await XCTUnwrap(search.advance()).value;XCTAssertEqual(search.phase,.end);XCTAssertEqual(search.copyText(side:.previous),first)
        try await XCTUnwrap(search.advance(direction:.forward)).value;XCTAssertTrue(try XCTUnwrap(search.copyText(side:.current)).contains("Byte range: 5–7"))
    }
    func testClipboardSelectionAndQueryGuards() async throws {
        let actions=AppActions(model:ComparisonModel(reader:HexCopyUnusedReader()))
        let selection=FocusedValueSelection(entitlementKey:"key",pathPreview:"Value",previous:.data(Data([0,128,255])),current:.data(Data([1])))
        actions.focusedValue=selection
        let search=FocusedHexSearch(source:Data([0,128,255]));search.setQuery("0080FF");try await XCTUnwrap(search.find()).value
        let clipboard=NSPasteboard.withUniqueName();defer { clipboard.releaseGlobally() }
        actions.copyHexMatchDetails(search,side:.previous,selectionID:selection.id,to:clipboard)
        let saved=clipboard.string(forType:.string);XCTAssertEqual(saved,search.copyText(side:.previous))
        actions.copyHexMatchDetails(search,side:.current,selectionID:UUID(),to:clipboard);XCTAssertEqual(clipboard.string(forType:.string),saved)
        actions.focusedValue=nil;actions.copyHexMatchDetails(search,side:.current,selectionID:selection.id,to:clipboard);XCTAssertEqual(clipboard.string(forType:.string),saved)
        actions.focusedValue=selection;search.setQuery("FF");actions.copyHexMatchDetails(search,side:.previous,selectionID:selection.id,to:clipboard);XCTAssertEqual(clipboard.string(forType:.string),saved)
    }
    func testRunningAndLateCompletionCannotCopyStaleMatch() async throws {
        let search=FocusedHexSearch(source:Data([0,0]),runner:{ cursor in
            let task=Task.detached { () -> (HexByteCursor,HexByteCursor.Step) in
                try await Task.sleep(for:.milliseconds(10));var next=cursor;let result=try next.step();return(next,result)
            };return try await task.value
        })
        search.setQuery("00");try await XCTUnwrap(search.find()).value
        let task=try XCTUnwrap(search.advance());XCTAssertNil(search.copyText(side:.previous))
        search.setQuery("FF");await task.value;XCTAssertNil(search.copyText(side:.previous))
        search.setQuery("00");try await XCTUnwrap(search.find()).value;XCTAssertNotNil(search.copyText(side:.current));search.cancel();XCTAssertNil(search.copyText(side:.current))
    }
}
private actor HexCopyUnusedReader: SnapshotReading {
    func read(at url:URL,architecture:Architecture) async throws -> EntitlementSnapshot { throw CancellationError() }
}
