import AppKit
import XCTest
import EntitlementDiffCore
import EntitlementDiffModel
@testable import EntitlementDiffApp

@MainActor final class TextMatchCopyTests: XCTestCase {
    func testExactUnicodeControlEscapesAndCrossPageRange() async throws {
        let query="🙂e\u{301}\u{200B}\n\"\\",search=FocusedStringSearch(source:String(repeating:"a",count:511)+query)
        search.setQuery(.init(value:query));XCTAssertNil(search.copyText(side:.previous));try await XCTUnwrap(search.find()).value
        let text=try XCTUnwrap(search.copyText(side:.previous))
        XCTAssertTrue(text.hasPrefix("Previous text match details\nUTF-8 byte range: 512–524"))
        XCTAssertTrue(text.contains("Starting Unicode scalar position: 512"));XCTAssertTrue(text.contains("Match length: 13 UTF-8 bytes"))
        XCTAssertTrue(text.contains("\\u{1F642}\\u{0065}\\u{0301}\\u{200B}\\u{000A}\\u{0022}\\u{005C}"))
        XCTAssertTrue(text.contains("F0 9F 99 82 65 CC 81 E2 80 8B 0A 22 5C"));XCTAssertFalse(text.contains("C3 A9"))
    }
    func testMaximumOutputAndCanonicalSpellingRemainComplete() async throws {
        for query in [String(repeating:"\u{7F}",count:1024),String(repeating:"🙂",count:256),"é","e\u{301}"] {
            let search=FocusedStringSearch(source:query);search.setQuery(.init(value:query));try await XCTUnwrap(search.find()).value
            let text=try XCTUnwrap(search.copyText(side:.current))
            XCTAssertLessThanOrEqual(text.utf8.count,FocusedStringSearch.copyByteLimit)
            let hex=query.utf8.map { String(format:"%02X",$0) }.joined(separator:" ")
            XCTAssertTrue(text.contains("UTF-8: "+hex+"\n"));XCTAssertFalse(text.contains("…"))
        }
    }
    func testClipboardSelectionGuardsAndCursorPreservation() async throws {
        let actions=AppActions(model:ComparisonModel(reader:TextCopyUnusedReader()))
        let selection=FocusedValueSelection(entitlementKey:"key",pathPreview:"Value",previous:.string("é é"),current:.string("x"))
        actions.focusedValue=selection
        let search=FocusedStringSearch(source:"é é");search.setQuery(.init(value:"é"));try await XCTUnwrap(search.find()).value
        let revision=search.matchRevision,reveal=search.revealRevision
        let clipboard=NSPasteboard.withUniqueName();defer { clipboard.releaseGlobally() }
        actions.copyTextMatchDetails(search,side:.previous,selectionID:selection.id,to:clipboard)
        let saved=clipboard.string(forType:.string);XCTAssertEqual(saved,search.copyText(side:.previous))
        XCTAssertEqual(search.matchRevision,revision);XCTAssertEqual(search.revealRevision,reveal)
        actions.copyTextMatchDetails(search,side:.current,selectionID:UUID(),to:clipboard);XCTAssertEqual(clipboard.string(forType:.string),saved)
        actions.focusedValue=nil;actions.copyTextMatchDetails(search,side:.current,selectionID:selection.id,to:clipboard);XCTAssertEqual(clipboard.string(forType:.string),saved)
        try await XCTUnwrap(search.advance()).value;XCTAssertEqual(search.match?.byteOffset,3)
        try await XCTUnwrap(search.advance(direction:.backward)).value;let first=search.copyText(side:.previous)
        try await XCTUnwrap(search.advance()).value;XCTAssertEqual(search.phase,.end);XCTAssertEqual(search.copyText(side:.previous),first)
    }
    func testRunningQueryAndDismissalRejectStaleClipboardPayload() async throws {
        let search=FocusedStringSearch(source:"xx",runner:{ cursor in
            let task=Task.detached { () -> (StringValueSearch,StringValueSearch.Step) in
                try await Task.sleep(for:.milliseconds(10));var next=cursor;let result=try next.step();return(next,result)
            };return try await task.value
        })
        search.setQuery(.init(value:"x"));try await XCTUnwrap(search.find()).value
        let work=try XCTUnwrap(search.advance());XCTAssertNil(search.copyText(side:.previous))
        search.setQuery(.init(value:"y"));await work.value;XCTAssertNil(search.copyText(side:.previous))
        search.setQuery(.init(value:"x"));try await XCTUnwrap(search.find()).value;XCTAssertNotNil(search.copyText(side:.current));search.cancel();XCTAssertNil(search.copyText(side:.current))
    }
}
private actor TextCopyUnusedReader: SnapshotReading {
    func read(at url:URL,architecture:Architecture) async throws -> EntitlementSnapshot { throw CancellationError() }
}
