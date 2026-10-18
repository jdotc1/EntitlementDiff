import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor final class HexRevealTests: XCTestCase {
    func testRevealExactSlicedContextAndForwardCursor() async throws {
        let search=FocusedHexSearch(source:Data([9,0,128,255,1,0,128,255,9])[1..<8])
        XCTAssertFalse(search.reveal());search.setQuery("00 80 FF")
        try await XCTUnwrap(search.find()).value
        let context=search.context,revision=search.revision,message=search.message
        XCTAssertTrue(search.reveal());XCTAssertNotEqual(search.revision,revision)
        XCTAssertEqual(search.matchOffset,0);XCTAssertEqual(search.context,context);XCTAssertEqual(search.message,message)
        XCTAssertEqual(search.phase,.matched);XCTAssertEqual(search.direction,.forward)
        XCTAssertTrue(try XCTUnwrap(context).contains("[00 80 FF]"))
        try await XCTUnwrap(search.advance()).value;XCTAssertEqual(search.matchOffset,4)
    }
    func testRevealPreservesBackwardAndCompletedBoundary() async throws {
        let search=FocusedHexSearch(source:Data([0,0,0]));search.setQuery("00 00")
        try await XCTUnwrap(search.find()).value;try await XCTUnwrap(search.advance()).value
        try await XCTUnwrap(search.advance(direction:.backward)).value
        XCTAssertTrue(search.reveal());XCTAssertEqual(search.direction,.backward)
        try await XCTUnwrap(search.advance()).value;XCTAssertEqual(search.phase,.end)
        let message=search.message;XCTAssertTrue(search.reveal());XCTAssertEqual(search.message,message)
        XCTAssertFalse(search.canSearch(.backward));XCTAssertTrue(search.canSearch(.forward))
        try await XCTUnwrap(search.advance(direction:.forward)).value;XCTAssertEqual(search.matchOffset,1)
        try await XCTUnwrap(search.advance()).value;XCTAssertEqual(search.phase,.end)
        XCTAssertTrue(search.reveal());XCTAssertEqual(search.matchOffset,1)
    }
    func testRevealPausedWorkDoesNotRestartAndRetainsNavigationAndDifference() async throws {
        let data=Data([255])+Data(repeating:0,count:40000)+Data([255])
        let search=FocusedHexSearch(source:data);search.setQuery("FF")
        try await XCTUnwrap(search.find()).value;try await XCTUnwrap(search.advance()).value
        XCTAssertEqual(search.phase,.paused);XCTAssertTrue(search.reveal());XCTAssertEqual(search.phase,.paused)
        var navigation=DataByteNavigation();navigation.setInput("20");XCTAssertTrue(navigation.go(data:data));let manual=navigation.context
        let difference=FocusedDataDifference(previous:data,current:Data([128]));try await XCTUnwrap(difference.find()).value
        let diffRevision=difference.revision,copy=difference.copyDetails
        XCTAssertTrue(search.reveal());XCTAssertEqual(navigation.context,manual);XCTAssertEqual(difference.revision,diffRevision);XCTAssertEqual(difference.copyDetails,copy)
        try await XCTUnwrap(search.advance()).value;XCTAssertEqual(search.matchOffset,40001)
        var page=LeafPageNavigation();page.select(0,pageCount:53)
        XCTAssertTrue(search.reveal());page.select(try XCTUnwrap(search.matchOffset)/LeafValueDocument.dataBytesPerPage,pageCount:53)
        XCTAssertEqual(page.index,52)
    }
    func testRunningAndStaleResultsCannotRevealAfterQueryOrDismissal() async throws {
        let search=FocusedHexSearch(source:Data([0,0]),runner:{ cursor in
            let work=Task.detached { () -> (HexByteCursor,HexByteCursor.Step) in
                try await Task.sleep(for:.milliseconds(10));var next=cursor;let result=try next.step();return(next,result)
            };return try await work.value
        })
        search.setQuery("00");try await XCTUnwrap(search.find()).value
        let next=try XCTUnwrap(search.advance());let revision=search.revision
        XCTAssertFalse(search.canReveal);XCTAssertFalse(search.reveal());XCTAssertEqual(search.revision,revision)
        search.setQuery("FF");await next.value;XCTAssertFalse(search.reveal());XCTAssertNil(search.context)
        search.setQuery("00");try await XCTUnwrap(search.find()).value;XCTAssertTrue(search.reveal())
        search.cancel();XCTAssertFalse(search.reveal());XCTAssertNil(search.matchOffset)
    }
}
