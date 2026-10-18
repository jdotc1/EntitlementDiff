import XCTest
import Foundation
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor final class ClearFindTests: XCTestCase {
    func testTextClearDropsMatchWithoutChangingRevisionsOrOtherPane() async throws {
        let a = FocusedStringSearch(source: "🙂e\u{301}"), b = FocusedStringSearch(source: "x")
        a.setQuery(.init(value: "e\u{301}")); b.setQuery(.init(value: "x"))
        try await XCTUnwrap(a.find()).value; try await XCTUnwrap(b.find()).value
        let matchRevision = a.matchRevision, revealRevision = a.revealRevision
        a.clear()
        XCTAssertEqual(a.input.value, ""); XCTAssertEqual(a.phase, .ready)
        XCTAssertNil(a.match); XCTAssertNil(a.copyText(side: .previous)); XCTAssertFalse(a.canReveal)
        XCTAssertEqual(a.matchRevision, matchRevision); XCTAssertEqual(a.revealRevision, revealRevision)
        XCTAssertNotNil(b.match)
        a.setQuery(.init(value: "🙂")); try await XCTUnwrap(a.find()).value
        XCTAssertEqual(a.match?.byteOffset, 0)
    }
    func testHexClearDropsContextAndPreservesOtherPane() async throws {
        let a = FocusedHexSearch(source: Data([0,128,255])), b = FocusedHexSearch(source: Data([255]))
        a.setQuery("80 FF"); b.setQuery("FF")
        try await XCTUnwrap(a.find()).value; try await XCTUnwrap(b.find()).value
        let revision = a.revision
        a.clear()
        XCTAssertEqual(a.query, ""); XCTAssertEqual(a.phase, .ready)
        XCTAssertNil(a.matchOffset); XCTAssertNil(a.context); XCTAssertNil(a.copyText(side: .current))
        XCTAssertFalse(a.canReveal); XCTAssertEqual(a.revision, revision); XCTAssertEqual(b.matchOffset, 0)
        a.setQuery("00"); try await XCTUnwrap(a.find()).value; XCTAssertEqual(a.matchOffset, 0)
    }
    func testClearRejectsLateTextAndHexResults() async throws {
        let text = FocusedStringSearch(source: "x", runner: { cursor in
            let task = Task.detached { var next = cursor; try await Task.sleep(for: .milliseconds(20)); return (next, try next.step()) }
            return try await task.value
        })
        let hex = FocusedHexSearch(source: Data([255]), runner: { cursor in
            let task = Task.detached { var next = cursor; try await Task.sleep(for: .milliseconds(20)); return (next, try next.step()) }
            return try await task.value
        })
        text.setQuery(.init(value: "x")); hex.setQuery("FF")
        let t = try XCTUnwrap(text.find()), h = try XCTUnwrap(hex.find())
        text.clear(); hex.clear(); await t.value; await h.value
        XCTAssertEqual(text.phase, .ready); XCTAssertEqual(hex.phase, .ready)
        XCTAssertNil(text.match); XCTAssertNil(hex.matchOffset); XCTAssertNil(hex.context)
        XCTAssertEqual(text.input.value, ""); XCTAssertEqual(hex.query, "")
    }
}
