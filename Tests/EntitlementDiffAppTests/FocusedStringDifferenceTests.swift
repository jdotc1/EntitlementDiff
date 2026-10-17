import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class FocusedStringDifferenceTests: XCTestCase {
    func testContinuationRevealAndRestartAreIndependentOfFind() async throws {
        let prefix = String(repeating: "x", count: 16385)
        let session = FocusedStringDifference(previous: prefix + "a", current: prefix + "b")
        let search = FocusedStringSearch(source: "target")
        search.setQuery(.init(value: "target")); try await XCTUnwrap(search.find()).value
        try await XCTUnwrap(session.find()).value
        XCTAssertEqual(session.phase, .paused); XCTAssertNil(session.position)
        try await XCTUnwrap(session.advance()).value
        XCTAssertEqual(session.position?.byteOffset, 16385)
        XCTAssertEqual(session.position?.pageIndex, 32)
        XCTAssertEqual(session.phase, .different)
        let revision = session.revision
        session.reveal(); XCTAssertNotEqual(session.revision, revision)
        XCTAssertNil(session.advance())
        XCTAssertEqual(search.match?.byteOffset, 0)
        XCTAssertEqual(search.input.value, "target")
        session.cancel(); XCTAssertNil(session.position)
        try await XCTUnwrap(session.find()).value
        XCTAssertEqual(session.phase, .paused)
        let equal = FocusedStringDifference(previous: "🙂", current: "🙂")
        try await XCTUnwrap(equal.find()).value
        XCTAssertEqual(equal.phase, .equal)
        XCTAssertTrue(equal.message.contains("No difference"))
    }
    func testDismissalAndRestartSuppressDeliberatelyLateDifference() async throws {
        let gate = DifferenceGate()
        let session = FocusedStringDifference(previous: "a", current: "", runner: { cursor in
            var next = cursor; let result = try next.step()
            await gate.wait(); return (next, result)
        })
        let old = try XCTUnwrap(session.find())
        while !(await gate.entered) { await Task.yield() }
        session.cancel(); await gate.release(); await old.value
        XCTAssertNil(session.position); XCTAssertEqual(session.phase, .ready)
        let first = try XCTUnwrap(session.find())
        let second = try XCTUnwrap(session.find())
        await first.value; await second.value
        XCTAssertEqual(session.phase, .different)
        XCTAssertEqual(session.position?.currentByteCount, 0)
        XCTAssertNil(session.advance())
    }
}
private actor DifferenceGate {
    var entered = false
    private var open = false
    private var waiter: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; if !open { await withCheckedContinuation { waiter = $0 } } }
    func release() { open = true; waiter?.resume(); waiter = nil }
}
