import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor final class TextMatchRevealTests: XCTestCase {
    func testRevealExactUTF8AndCrossPageHighlight() async throws {
        let query="🙂e\u{301}\u{200B}",text=String(repeating:"a",count:511)+"🙂e\u{301}\u{200B}tail"
        let search=FocusedStringSearch(source:text);XCTAssertFalse(search.reveal())
        search.setQuery(.init(value:query));try await XCTUnwrap(search.find()).value
        let range=try XCTUnwrap(search.matchByteRange),revision=search.matchRevision
        XCTAssertEqual(range,511..<521);let reveal=search.revealRevision;XCTAssertTrue(search.reveal())
        XCTAssertNotEqual(search.revealRevision,reveal);XCTAssertEqual(search.matchRevision,revision);XCTAssertEqual(search.matchByteRange,range)
        let doc=try LeafValueDocument(leaf:XCTUnwrap(InspectorLeaf(.string(text))))
        let first=try XCTUnwrap(doc.stringPage(onPage:0,matching:range)),second=try XCTUnwrap(doc.stringPage(onPage:1,matching:range))
        XCTAssertTrue(first.continuesAfter);XCTAssertTrue(second.continuesBefore)
        XCTAssertEqual((first.text as NSString).substring(with:try XCTUnwrap(first.highlight)),"🙂")
        XCTAssertEqual(search.input.value.utf8.map{$0},query.utf8.map{$0})
    }
    func testRevealRetainsManualScalarAndDifferenceState() async throws {
        let text=String(repeating:"🙂",count:512)+"e\u{301}target"
        let doc=try LeafValueDocument(leaf:XCTUnwrap(InspectorLeaf(.string(text))))
        let search=FocusedStringSearch(source:text);search.setQuery(.init(value:"target"));try await XCTUnwrap(search.find()).value
        var nav=StringScalarNavigation();nav.setInput("514");XCTAssertTrue(nav.go(document:doc));let manual=nav.position,copy=nav.copyText(side:.previous)
        let diff=FocusedStringDifference(previous:text,current:"different");try await XCTUnwrap(diff.find()).value
        let revision=diff.revision,details=diff.copyDetails
        XCTAssertTrue(search.reveal());XCTAssertEqual(nav.position,manual);XCTAssertEqual(nav.copyText(side:.previous),copy)
        XCTAssertEqual(diff.revision,revision);XCTAssertEqual(diff.copyDetails,details);XCTAssertEqual(search.match?.pageIndex,1)
    }
    func testRevealPreservesCursorDirectionAndCompletedSearch() async throws {
        let search=FocusedStringSearch(source:"é e\u{301} é")
        search.setQuery(.init(value:"é"));try await XCTUnwrap(search.find()).value
        XCTAssertTrue(search.reveal());try await XCTUnwrap(search.advance()).value;XCTAssertEqual(search.match?.byteOffset,7)
        try await XCTUnwrap(search.advance(direction:.backward)).value;XCTAssertEqual(search.match?.byteOffset,0)
        XCTAssertTrue(search.reveal());XCTAssertEqual(search.direction,.backward)
        try await XCTUnwrap(search.advance()).value;XCTAssertEqual(search.phase,.end)
        let message=search.message;XCTAssertTrue(search.reveal());XCTAssertEqual(search.message,message)
        try await XCTUnwrap(search.advance(direction:.forward)).value;XCTAssertEqual(search.match?.byteOffset,7)
        try await XCTUnwrap(search.advance()).value;XCTAssertTrue(search.reveal());XCTAssertEqual(search.phase,.end)
    }
    func testRunningQueryAndDismissalRejectLateReveal() async throws {
        let search=FocusedStringSearch(source:"xx",runner:{ cursor in
            let work=Task.detached { () -> (StringValueSearch,StringValueSearch.Step) in
                try await Task.sleep(for:.milliseconds(10));var next=cursor;let result=try next.step();return(next,result)
            };return try await work.value
        })
        search.setQuery(.init(value:"x"));try await XCTUnwrap(search.find()).value
        let task=try XCTUnwrap(search.advance());XCTAssertFalse(search.canReveal);XCTAssertFalse(search.reveal())
        search.setQuery(.init(value:"y"));await task.value;XCTAssertNil(search.match);XCTAssertFalse(search.reveal())
        search.setQuery(.init(value:"x"));try await XCTUnwrap(search.find()).value;XCTAssertTrue(search.reveal())
        search.cancel();XCTAssertNil(search.matchByteRange);XCTAssertFalse(search.reveal())
    }
}
