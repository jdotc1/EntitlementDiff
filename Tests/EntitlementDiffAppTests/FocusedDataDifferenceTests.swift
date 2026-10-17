import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class FocusedDataDifferenceTests: XCTestCase {
    func testNextContextCompletionAndRestart() async throws {
        let session = FocusedDataDifference(previous: Data([0, 1, 2]), current: Data([9, 8, 2, 0]))
        XCTAssertNil(session.next())
        try await XCTUnwrap(session.find()).value
        try await XCTUnwrap(session.next()).value
        XCTAssertEqual(session.differenceCount, 2); XCTAssertEqual(session.position?.byteOffset, 1)
        XCTAssertEqual(session.currentContext?.markedHex, "[08]")
        XCTAssertTrue(session.message.contains("Difference 2"))
        try await XCTUnwrap(session.next()).value
        XCTAssertEqual(session.differenceCount, 3); XCTAssertEqual(session.previousContext?.markedHex, "[EOF]")
        let saved = session.currentContext
        try await XCTUnwrap(session.next()).value
        XCTAssertEqual(session.phase, .finished); XCTAssertTrue(session.message.contains("No further differences"))
        XCTAssertEqual(session.currentContext, saved); XCTAssertNil(session.next()); XCTAssertNil(session.advance())
        try await XCTUnwrap(session.find()).value
        XCTAssertEqual(session.differenceCount, 1); XCTAssertEqual(session.position?.byteOffset, 0)
    }
    func testNextPausedKeepsLastResultUntilContinuation() async throws {
        let a = Data(repeating: 0, count: 20002)
        var b = a; b[0] = 1; b[20001] = 0x80
        let session = FocusedDataDifference(previous: a, current: b)
        try await XCTUnwrap(session.find()).value
        try await XCTUnwrap(session.next()).value
        XCTAssertEqual(session.phase, .paused); XCTAssertEqual(session.position?.byteOffset, 0)
        XCTAssertEqual(session.currentContext?.markedHex, "[01]")
        XCTAssertTrue(session.message.contains("No further difference yet")); XCTAssertNil(session.next())
        try await XCTUnwrap(session.advance()).value
        XCTAssertEqual(session.position?.byteOffset, 20001); XCTAssertEqual(session.differenceCount, 2)
        XCTAssertEqual(session.currentContext?.markedHex, "[80]")
    }
    func testCancelledNextCannotReplaceNewFirstResult() async throws {
        let gate = NextDifferenceGate()
        let session = FocusedDataDifference(previous: Data([0, 1]), current: Data([9, 8]), runner: { cursor in
            var next = cursor; let result = try next.step()
            await gate.waitOnSecond(); return (next, result)
        })
        try await XCTUnwrap(session.find()).value
        let late = try XCTUnwrap(session.next())
        while !(await gate.entered) { await Task.yield() }
        try await XCTUnwrap(session.find()).value
        await gate.release(); await late.value
        XCTAssertEqual(session.differenceCount, 1); XCTAssertEqual(session.position?.byteOffset, 0)
        XCTAssertEqual(session.currentContext?.markedHex, "[09]")
    }
    func testHexContextPublishesWithResultAndClearsOnRestart() async throws {
        let session = FocusedDataDifference(previous: Data([0, 0x7F]), current: Data([0, 0x80, 0xFF]))
        XCTAssertNil(session.previousContext); XCTAssertNil(session.currentContext)
        try await XCTUnwrap(session.find()).value
        XCTAssertEqual(session.previousContext?.markedHex, "[7F]")
        XCTAssertEqual(session.currentContext?.markedHex, "[80]")
        XCTAssertEqual(session.currentContext?.afterHex, "FF")
        let saved = session.currentContext
        session.reveal(); XCTAssertEqual(session.currentContext, saved)
        let restart = try XCTUnwrap(session.find())
        XCTAssertNil(session.previousContext); XCTAssertNil(session.currentContext)
        await restart.value
        session.cancel(); XCTAssertNil(session.previousContext); XCTAssertNil(session.currentContext)
        let prefix = FocusedDataDifference(previous: Data(), current: Data([0]))
        try await XCTUnwrap(prefix.find()).value
        XCTAssertEqual(prefix.previousContext?.markedHex, "[EOF]")
        XCTAssertEqual(prefix.currentContext?.markedHex, "[00]")
    }
    func testCancelledResultCannotPublishHexContext() async throws {
        let gate = DataDifferenceGate()
        let session = FocusedDataDifference(previous: Data([0x7F]), current: Data([0x80]), runner: { cursor in
            var next = cursor; let result = try next.step()
            await gate.wait(); return (next, result)
        })
        let work = try XCTUnwrap(session.find())
        while !(await gate.entered) { await Task.yield() }
        session.cancel(); await gate.release(); await work.value
        XCTAssertNil(session.position); XCTAssertNil(session.previousContext); XCTAssertNil(session.currentContext)
        XCTAssertEqual(session.phase, .ready)
    }
    func testExplicitContinuationRevealRestartAndEquality() async throws {
        let a = Data(repeating: 0, count: 16385)
        var b = a; b.append(0x80)
        let session = FocusedDataDifference(previous: a, current: b)
        try await XCTUnwrap(session.find()).value
        XCTAssertEqual(session.phase, .paused); XCTAssertNil(session.position)
        try await XCTUnwrap(session.advance()).value
        XCTAssertEqual(session.position?.byteOffset, 16385)
        XCTAssertEqual(session.position?.previousLabel, "End of data")
        let revision = session.revision
        session.reveal(); XCTAssertNotEqual(session.revision, revision)
        XCTAssertNil(session.advance())
        session.cancel(); XCTAssertNil(session.position)
        try await XCTUnwrap(session.find()).value
        XCTAssertEqual(session.phase, .paused)
        let equal = FocusedDataDifference(previous: Data([0, 0xFF]), current: Data([0, 0xFF]))
        try await XCTUnwrap(equal.find()).value
        XCTAssertEqual(equal.phase, .equal); XCTAssertTrue(equal.message.contains("No difference"))
    }
    func testDismissedComputedByteResultCannotPublishLate() async throws {
        let gate = DataDifferenceGate()
        let session = FocusedDataDifference(previous: Data([0x7F]), current: Data([0x80]), runner: { cursor in
            var next = cursor; let result = try next.step()
            await gate.wait(); return (next, result)
        })
        let work = try XCTUnwrap(session.find())
        while !(await gate.entered) { await Task.yield() }
        session.cancel(); await gate.release(); await work.value
        XCTAssertNil(session.position); XCTAssertEqual(session.phase, .ready)
        try await XCTUnwrap(session.find()).value
        XCTAssertEqual(session.position?.currentByte, 0x80)
    }
}
private actor DataDifferenceGate {
    var entered = false
    private var open = false
    private var waiter: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; if !open { await withCheckedContinuation { waiter = $0 } } }
    func release() { open = true; waiter?.resume(); waiter = nil }
}

private actor NextDifferenceGate {
    var entered = false
    private var calls = 0
    private var waiter: CheckedContinuation<Void, Never>?
    func waitOnSecond() async {
        calls += 1
        if calls == 2 { entered = true; await withCheckedContinuation { waiter = $0 } }
    }
    func release() { waiter?.resume(); waiter = nil }
}
