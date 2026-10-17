import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class FocusedBackwardSearchTests: XCTestCase {
    func testDirectionChangesBeginningAndQueryReset() async throws {
        let session = FocusedStringSearch(source: "aaaa")
        XCTAssertNil(session.advance(direction: .backward))
        session.setQuery(.init(value: "aa"))
        try await XCTUnwrap(session.find()).value
        try await XCTUnwrap(session.advance()).value
        XCTAssertEqual(session.match?.byteOffset, 1)
        try await XCTUnwrap(session.advance(direction: .backward)).value
        XCTAssertEqual(session.match?.byteOffset, 0)
        try await XCTUnwrap(session.advance()).value
        XCTAssertEqual(session.phase, .end)
        XCTAssertTrue(session.message.contains("beginning"))
        XCTAssertFalse(session.canSearch(.backward))
        XCTAssertTrue(session.canSearch(.forward))
        try await XCTUnwrap(session.advance(direction: .forward)).value
        XCTAssertEqual(session.match?.byteOffset, 1)
        session.setQuery(.init(value: "a"))
        XCTAssertNil(session.match)
        XCTAssertFalse(session.canSearch(.backward))
    }
    func testBackwardPauseAndLateDirectionResultAreSuppressed() async throws {
        let gate = BackwardGate()
        let session = FocusedStringSearch(source: "target" + String(repeating: "x", count: 32769) + "target", runner: { cursor in
            var next = cursor
            let result = try next.step()
            if cursor.direction == .backward { await gate.wait() }
            return (next, result)
        })
        session.setQuery(.init(value: "target"))
        try await XCTUnwrap(session.find()).value
        while session.match?.byteOffset == 0 { try await XCTUnwrap(session.advance()).value }
        let pending = try XCTUnwrap(session.advance(direction: .backward))
        while !(await gate.entered) { await Task.yield() }
        try await XCTUnwrap(session.advance(direction: .forward)).value
        XCTAssertEqual(session.phase, .end)
        await gate.release()
        await pending.value
        XCTAssertEqual(session.phase, .end)
        XCTAssertEqual(session.direction, .forward)
        try await XCTUnwrap(session.advance(direction: .backward)).value
        XCTAssertEqual(session.phase, .paused)
        XCTAssertTrue(session.message.contains("backward"))
        try await XCTUnwrap(session.advance()).value
        XCTAssertEqual(session.match?.byteOffset, 0)
        session.cancel()
        XCTAssertNil(session.match)
    }
}
private actor BackwardGate {
    var entered = false
    private var open = false
    private var waiter: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; if !open { await withCheckedContinuation { waiter = $0 } } }
    func release() { open = true; waiter?.resume(); waiter = nil }
}
