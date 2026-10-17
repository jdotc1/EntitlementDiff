import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class UnicodeDifferencePublicationTests: XCTestCase {
    func testLateDetailCannotSurviveCancellationAndRevealRetainsCapturedScalars() async throws {
        let gate = UnicodeDetailGate()
        let session = FocusedStringDifference(previous: "é", current: "e\u{301}", runner: { cursor in
            var next = cursor; let result = try next.step()
            await gate.wait(); return (next, result)
        })
        let pending = try XCTUnwrap(session.find())
        while !(await gate.entered) { await Task.yield() }
        session.cancel(); await gate.release(); await pending.value
        XCTAssertNil(session.position?.previousDetail)
        XCTAssertEqual(session.phase, .ready)
        try await XCTUnwrap(session.find()).value
        let captured = try XCTUnwrap(session.position)
        XCTAssertEqual(captured.previousDetail.utf8Bytes, "C3 A9")
        XCTAssertEqual(captured.currentDetail.utf8Bytes, "65")
        let revision = session.revision
        session.reveal()
        XCTAssertNotEqual(session.revision, revision)
        XCTAssertEqual(session.position, captured)
        session.cancel(); XCTAssertNil(session.position)
    }
}
private actor UnicodeDetailGate {
    var entered = false
    private var open = false
    private var waiter: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; if !open { await withCheckedContinuation { waiter = $0 } } }
    func release() { open = true; waiter?.resume(); waiter = nil }
}
