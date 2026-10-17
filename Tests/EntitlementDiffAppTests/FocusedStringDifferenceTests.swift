import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class FocusedStringDifferenceTests: XCTestCase {
    func testNextDetailsCompletionRestartAndIndependentFind() async throws {
        let session = FocusedStringDifference(previous: "aé", current: "🙂\u{200B}x")
        let search = FocusedStringSearch(source: "target")
        search.setQuery(.init(value: "target")); try await XCTUnwrap(search.find()).value
        XCTAssertNil(session.next()); try await XCTUnwrap(session.find()).value
        try await XCTUnwrap(session.next()).value
        XCTAssertEqual(session.differenceCount, 2); XCTAssertEqual(session.position?.previousByteOffset, 1)
        XCTAssertEqual(session.position?.currentByteOffset, 4)
        XCTAssertEqual(session.position?.currentDetail.utf8Bytes, "E2 80 8B")
        XCTAssertTrue(session.message.contains("Previous byte 2, Current byte 5"))
        XCTAssertEqual(search.input.value, "target"); XCTAssertEqual(search.match?.byteOffset, 0)
        try await XCTUnwrap(session.next()).value
        XCTAssertNil(session.position?.previousScalar)
        try await XCTUnwrap(session.next()).value
        XCTAssertEqual(session.phase, .finished); XCTAssertTrue(session.message.contains("No further differences"))
        XCTAssertNil(session.next()); XCTAssertNil(session.advance())
        let saved = session.position; session.reveal(); XCTAssertEqual(session.position, saved)
        try await XCTUnwrap(session.find()).value
        XCTAssertEqual(session.differenceCount, 1); XCTAssertEqual(session.position?.scalarOffset, 0)
    }
    func testNextPauseRetainsLastPositionAndResumes() async throws {
        let gap = String(repeating: "🙂", count: 5000)
        let session = FocusedStringDifference(previous: "a" + gap + "x", current: "🙂" + gap + "y")
        try await XCTUnwrap(session.find()).value; try await XCTUnwrap(session.next()).value
        XCTAssertEqual(session.phase, .paused); XCTAssertEqual(session.position?.scalarOffset, 0)
        XCTAssertTrue(session.message.contains("No further difference yet")); XCTAssertNil(session.next())
        try await XCTUnwrap(session.advance()).value
        XCTAssertEqual(session.position?.scalarOffset, 5001); XCTAssertEqual(session.differenceCount, 2)
        XCTAssertEqual(session.position?.currentByteOffset, 20004)
    }
    func testLateNextCannotOverwriteRestartedUnicodeDetails() async throws {
        let gate = NextStringDifferenceGate()
        let session = FocusedStringDifference(previous: "aé", current: "🙂x", runner: { cursor in
            var next = cursor; let result = try next.step(); await gate.waitOnSecond(); return (next, result)
        })
        try await XCTUnwrap(session.find()).value
        let old = try XCTUnwrap(session.next())
        while !(await gate.entered) { await Task.yield() }
        try await XCTUnwrap(session.find()).value
        await gate.release(); await old.value
        XCTAssertEqual(session.differenceCount, 1); XCTAssertEqual(session.position?.scalarOffset, 0)
        XCTAssertEqual(session.position?.currentDetail.utf8Bytes, "F0 9F 99 82")
    }
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

private actor NextStringDifferenceGate {
    var entered = false
    private var calls = 0
    private var waiter: CheckedContinuation<Void, Never>?
    func waitOnSecond() async {
        calls += 1
        if calls == 2 { entered = true; await withCheckedContinuation { waiter = $0 } }
    }
    func release() { waiter?.resume(); waiter = nil }
}
