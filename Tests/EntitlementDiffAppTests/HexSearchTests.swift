import Foundation
import XCTest
@testable import EntitlementDiffApp

@MainActor final class HexSearchTests: XCTestCase {
    func testSlicedBytesOverlapAndBoundaries() throws {
        var cursor = try HexByteCursor(source: Data([9,0,128,255,0,128,255,9])[1..<7], query: "00 80 fF")
        XCTAssertEqual(try cursor.step(limit: 2), .more)
        XCTAssertEqual(try cursor.step(limit: 1), .match(0))
        XCTAssertEqual(try cursor.step(), .match(3))
        XCTAssertEqual(try cursor.step(), .end)
        var overlap = try HexByteCursor(source: Data([0,0,0]), query: "0000")
        XCTAssertEqual(try overlap.step(), .match(0)); XCTAssertEqual(try overlap.step(), .match(1))
        XCTAssertEqual(try overlap.step(), .end)
    }
    func testStrictBoundedQueryAndPortions() throws {
        for query in ["", "0", "0 0", "GG", "00\n80", "００", String(repeating: "00", count: 129)] {
            XCTAssertThrowsError(try HexByteCursor(source: Data(), query: query))
        }
        var cursor = try HexByteCursor(source: Data(repeating: 0, count: 32768) + Data([128,255]), query: "00 80 FF")
        XCTAssertEqual(try cursor.step(), .more); XCTAssertEqual(try cursor.step(), .match(32767))
        XCTAssertEqual(try cursor.step(), .end)
        var empty = try HexByteCursor(source: Data(), query: "00")
        XCTAssertEqual(try empty.step(), .end)
    }
    func testModelContinuationContextAndStateIndependence() async throws {
        let search = FocusedHexSearch(source: Data(repeating: 0, count: 32768) + Data([128,255]))
        var nav = DataByteNavigation(); nav.setInput("2"); XCTAssertTrue(nav.go(data: Data([0,1,2])))
        let context = nav.context
        search.setQuery("00 80 FF"); try await XCTUnwrap(search.find()).value
        XCTAssertEqual(search.phase, .paused)
        try await XCTUnwrap(search.advance()).value
        XCTAssertEqual(search.phase, .matched); XCTAssertEqual(search.matchOffset,32767)
        XCTAssertTrue(try XCTUnwrap(search.context).contains("[00 80 FF]"))
        XCTAssertEqual(nav.context,context)
        try await XCTUnwrap(search.advance()).value; XCTAssertEqual(search.phase,.end)
        search.setQuery("GG"); XCTAssertNil(search.find()); XCTAssertEqual(search.phase,.invalid)
        search.setQuery(String(repeating:"0",count:10000)); XCTAssertEqual(search.query.utf8.count,384)
    }
    func testStaleCompletionAfterEditAndCancel() async throws {
        let search = FocusedHexSearch(source: Data([128]), runner: { cursor in
            try? await Task.sleep(for: .milliseconds(30))
            var next = cursor; let result = try next.step(); return (next,result)
        })
        search.setQuery("80"); let old = try XCTUnwrap(search.find()); search.setQuery("FF")
        await old.value; XCTAssertEqual(search.phase,.ready); XCTAssertNil(search.matchOffset)
        let current = try XCTUnwrap(search.find()); search.cancel(); await current.value
        XCTAssertEqual(search.phase,.ready); XCTAssertNil(search.context)
    }
}
