import Foundation
import XCTest
@testable import EntitlementDiffApp

@MainActor final class HexPreviousTests: XCTestCase {
    func testSlicedOriginalBytesOverlapAndDirectionChanges() throws {
        var cursor = try HexByteCursor(source: Data([9,0,128,255,0,128,255,9])[1..<7], query: "00 80 FF")
        XCTAssertEqual(try cursor.step(),.match(0)); XCTAssertEqual(try cursor.step(),.match(3))
        cursor = try cursor.searching(.backward)
        XCTAssertEqual(try cursor.step(limit:2),.more); XCTAssertEqual(try cursor.step(),.match(0))
        XCTAssertEqual(try cursor.step(),.end)
        cursor = try cursor.searching(.forward); XCTAssertEqual(try cursor.step(),.match(3))
        var overlap = try HexByteCursor(source:Data([0,0,0,0]),query:"00 00")
        XCTAssertEqual(try overlap.step(),.match(0)); XCTAssertEqual(try overlap.step(),.match(1)); XCTAssertEqual(try overlap.step(),.match(2))
        overlap = try overlap.searching(.backward)
        XCTAssertEqual(try overlap.step(),.match(1)); XCTAssertEqual(try overlap.step(),.match(0)); XCTAssertEqual(try overlap.step(),.end)
    }
    func testBackwardPortionBoundaryAndSingleByteFirst() throws {
        let source = Data([0,128,255]) + Data(repeating:1,count:32768) + Data([0,128,255])
        var cursor = try HexByteCursor(source:source,query:"00 80 FF")
        XCTAssertEqual(try cursor.step(),.match(0)); XCTAssertEqual(try cursor.step(),.more); XCTAssertEqual(try cursor.step(),.match(32771))
        cursor = try cursor.searching(.backward)
        XCTAssertEqual(try cursor.step(),.more); XCTAssertEqual(try cursor.step(),.match(0)); XCTAssertEqual(try cursor.step(),.end)
        var one = try HexByteCursor(source:Data([255]),query:"FF")
        XCTAssertEqual(try one.step(),.match(0)); one = try one.searching(.backward)
        XCTAssertEqual(try one.step(),.end); one = try one.searching(.forward); XCTAssertEqual(try one.step(),.end)
    }
    func testModelDirectionEndAndIndependentState() async throws {
        let data = Data([0,128,255,1,0,128,255])
        let search = FocusedHexSearch(source:data), other = FocusedHexSearch(source:data)
        var nav = DataByteNavigation();nav.setInput("2");XCTAssertTrue(nav.go(data:data));let manual=nav.context
        search.setQuery("0080FF");try await XCTUnwrap(search.find()).value
        try await XCTUnwrap(search.advance()).value;XCTAssertEqual(search.matchOffset,4)
        try await XCTUnwrap(search.advance(direction:.backward)).value;XCTAssertEqual(search.matchOffset,0)
        XCTAssertTrue(try XCTUnwrap(search.context).contains("[00 80 FF]"));XCTAssertEqual(search.direction,.backward)
        try await XCTUnwrap(search.advance()).value;XCTAssertEqual(search.phase,.end);XCTAssertTrue(search.message.contains("beginning"))
        XCTAssertFalse(search.canSearch(.backward));XCTAssertTrue(search.canSearch(.forward))
        try await XCTUnwrap(search.advance(direction:.forward)).value;XCTAssertEqual(search.matchOffset,4)
        XCTAssertEqual(nav.context,manual);XCTAssertEqual(other.phase,.ready);XCTAssertNil(other.matchOffset)
    }
    func testBackwardLateCompletionCannotSurviveQueryOrDismissal() async throws {
        let search = FocusedHexSearch(source:Data([0,0]),runner:{ cursor in
            // Simulate a native runner that completes despite cancellation.
            let task = Task.detached { () -> (HexByteCursor,HexByteCursor.Step) in
                try await Task.sleep(for:.milliseconds(10));var next=cursor;let result=try next.step();return(next,result)
            }
            return try await task.value
        })
        search.setQuery("00");try await XCTUnwrap(search.find()).value;try await XCTUnwrap(search.advance()).value
        let old=try XCTUnwrap(search.advance(direction:.backward));search.setQuery("FF");await old.value
        XCTAssertEqual(search.phase,.ready);XCTAssertNil(search.matchOffset);XCTAssertEqual(search.direction,.forward)
        search.setQuery("00");try await XCTUnwrap(search.find()).value;try await XCTUnwrap(search.advance()).value
        let dismissed=try XCTUnwrap(search.advance(direction:.backward));search.cancel();await dismissed.value
        XCTAssertEqual(search.phase,.ready);XCTAssertNil(search.context)
    }
}
