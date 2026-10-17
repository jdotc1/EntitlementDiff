import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class FocusedStringSearchTests: XCTestCase {
    func testExplicitContinuationEndAndRestart() async throws {
        let session = FocusedStringSearch(source: String(repeating: "x", count: 32768) + "target target")
        session.setQuery(.init(value: "target"))
        try await XCTUnwrap(session.find()).value
        XCTAssertEqual(session.phase, .paused)
        XCTAssertNil(session.match)
        XCTAssertTrue(session.canAdvance)
        try await XCTUnwrap(session.advance()).value
        XCTAssertEqual(session.match?.byteOffset, 32768)
        XCTAssertEqual(session.phase, .matched)
        try await XCTUnwrap(session.advance()).value
        XCTAssertEqual(session.match?.byteOffset, 32775)
        try await XCTUnwrap(session.advance()).value
        XCTAssertEqual(session.phase, .end)
        XCTAssertNil(session.advance())
        session.setQuery(.init(value: ""))
        XCTAssertNil(session.find())
        XCTAssertEqual(session.phase, .invalid)
    }
    func testRawQueryEditAndDismissalSuppressLateResult() async throws {
        let gate = SearchResultGate()
        let session = FocusedStringSearch(source: "é e\u{301}", runner: { cursor in
            var next = cursor
            let result = try next.step()
            await gate.wait()
            return (next, result) // Deliberately return a computed result after cancellation.
        })
        session.setQuery(.init(value: "é"))
        let work = try XCTUnwrap(session.find())
        while !(await gate.entered) { await Task.yield() }
        session.setQuery(.init(value: "e\u{301}"))
        await gate.release()
        await work.value
        XCTAssertEqual(Array(session.input.value.utf8), Array("e\u{301}".utf8))
        XCTAssertNil(session.match)
        XCTAssertEqual(session.phase, .ready)
        let pending = try XCTUnwrap(session.find())
        session.cancel()
        await gate.release()
        await pending.value
        XCTAssertNil(session.match)
        XCTAssertEqual(session.phase, .ready)
    }
}
private actor SearchResultGate {
    var entered = false
    private var open = false
    private var waiter: CheckedContinuation<Void, Never>?
    func wait() async {
        entered = true
        if !open { await withCheckedContinuation { waiter = $0 } }
    }
    func release() { open = true; waiter?.resume(); waiter = nil }
}
