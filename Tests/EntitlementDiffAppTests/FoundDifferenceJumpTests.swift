import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class FoundDifferenceJumpTests: XCTestCase {
    func testStrictBoundedOrdinalParsingAndRetainedRange() {
        var history = FoundDifferenceHistory<Int>()
        for n in 0..<70 { _ = history.append(n) }
        XCTAssertEqual(history.rangeLabel, "Found differences 7–70")
        XCTAssertEqual(history.select(input: "7")?.position, 6)
        XCTAssertFalse(history.canPrevious)
        XCTAssertEqual(history.select(input: "40")?.ordinal, 40)
        XCTAssertEqual(history.select(input: "70")?.ordinal, 70)
        for input in ["", "0", "6", "71", "-7", "+7", " 7", "7 ", "7.0", "٧", "７", "18446744073709551615", String(repeating: "9", count: 1000)] {
            XCTAssertNil(history.select(input: input), input)
            XCTAssertEqual(history.index, 63)
        }
        XCTAssertEqual(history.select(input: "0007")?.ordinal, 7)
    }
    func testDataJumpRestoresExactContextWithoutScanningAndResumesFrontier() async throws {
        let counter = JumpRunCounter()
        let model = FocusedDataDifference(previous: Data([0, 1, 2]), current: Data([9, 8, 7, 0]), runner: { cursor in
            await counter.increment(); var next = cursor; let result = try next.step(); return (next, result)
        })
        try await XCTUnwrap(model.find()).value
        for _ in 0..<3 { try await XCTUnwrap(model.next()).value }
        try await XCTUnwrap(model.next()).value
        XCTAssertEqual(model.phase, .finished)
        model.setJumpInput("2"); model.jumpToFound()
        XCTAssertEqual(model.position?.byteOffset, 1); XCTAssertEqual(model.currentContext?.markedHex, "[08]")
        XCTAssertEqual(model.phase, .different)
        let saved = model.position, revision = model.revision
        model.setJumpInput("5"); model.jumpToFound()
        XCTAssertEqual(model.position, saved); XCTAssertEqual(model.revision, revision); XCTAssertNotNil(model.jumpError)
        model.setJumpInput("4"); model.jumpToFound()
        XCTAssertEqual(model.phase, .finished); XCTAssertEqual(model.previousContext?.markedHex, "[EOF]")
        XCTAssertNil(model.jumpError); XCTAssertFalse(model.canNext)
        let runs = await counter.count; XCTAssertEqual(runs, 5)
        try await XCTUnwrap(model.find()).value
        XCTAssertEqual(model.foundRange, "Found differences 1–1"); XCTAssertEqual(model.jumpInput, "1")
    }
    func testStringJumpKeepsIndependentOffsetsAndContinuesAtFrontier() async throws {
        let model = FocusedStringDifference(previous: "aéZ", current: "🙂\u{200B}Yx")
        try await XCTUnwrap(model.find()).value
        for _ in 0..<2 { try await XCTUnwrap(model.next()).value }
        model.setJumpInput("2"); model.jumpToFound()
        XCTAssertEqual(model.position?.previousByteOffset, 1); XCTAssertEqual(model.position?.currentByteOffset, 4)
        XCTAssertEqual(model.position?.currentDetail.utf8Bytes, "E2 80 8B")
        model.setJumpInput("1"); model.jumpToFound(); XCTAssertFalse(model.canPrevious)
        model.setJumpInput("3"); model.jumpToFound()
        try await XCTUnwrap(model.next()).value
        XCTAssertEqual(model.differenceCount, 4); XCTAssertNil(model.position?.previousScalar)
        XCTAssertEqual(model.position?.currentScalar, "x")
        model.cancel(); XCTAssertNil(model.foundRange); XCTAssertEqual(model.jumpInput, ""); XCTAssertFalse(model.canJump)
    }
    func testBothSessionEvictionRejectsDiscardedAndFutureWithoutSelectionChange() async throws {
        let data = FocusedDataDifference(previous: Data(repeating: 0, count: 72), current: Data(repeating: 1, count: 72))
        let text = FocusedStringDifference(previous: String(repeating: "a", count: 72), current: String(repeating: "🙂", count: 72))
        try await XCTUnwrap(data.find()).value; try await XCTUnwrap(text.find()).value
        for _ in 1..<70 { try await XCTUnwrap(data.next()).value; try await XCTUnwrap(text.next()).value }
        for invalid in ["1", "71", "-1", " 7", String(repeating: "9", count: 1000)] {
            data.setJumpInput(invalid); data.jumpToFound(); text.setJumpInput(invalid); text.jumpToFound()
            XCTAssertEqual(data.differenceCount, 70); XCTAssertEqual(text.differenceCount, 70)
            XCTAssertNotNil(data.jumpError); XCTAssertNotNil(text.jumpError)
            XCTAssertLessThanOrEqual(data.jumpInput.utf8.count, 21)
        }
        data.setJumpInput("7"); data.jumpToFound(); text.setJumpInput("7"); text.jumpToFound()
        XCTAssertFalse(data.canPrevious); XCTAssertFalse(text.canPrevious)
        XCTAssertEqual(text.position?.currentByteOffset, 24)
        data.setJumpInput("70"); data.jumpToFound(); text.setJumpInput("70"); text.jumpToFound()
        try await XCTUnwrap(data.next()).value; try await XCTUnwrap(text.next()).value
        XCTAssertEqual(data.differenceCount, 71); XCTAssertEqual(text.differenceCount, 71)
    }
    func testPendingWorkRejectsJumpAndLateResultCannotRestoreClearedHistory() async throws {
        let gate = JumpPublicationGate()
        let model = FocusedStringDifference(previous: "aé", current: "🙂x", runner: { cursor in
            var next = cursor; let result = try next.step(); await gate.waitOnSecond(); return (next, result)
        })
        try await XCTUnwrap(model.find()).value; let pending = try XCTUnwrap(model.next())
        while !(await gate.entered) { await Task.yield() }
        model.setJumpInput("1"); model.jumpToFound(); XCTAssertFalse(model.canJump)
        XCTAssertEqual(model.differenceCount, 1)
        try await XCTUnwrap(model.find()).value; await gate.release(); await pending.value
        XCTAssertEqual(model.foundRange, "Found differences 1–1"); XCTAssertEqual(model.differenceCount, 1)
        XCTAssertEqual(model.position?.currentByteOffset, 0)
    }
}
private actor JumpRunCounter {
    var count = 0
    func increment() { count += 1 }
}
private actor JumpPublicationGate {
    var entered = false
    private var calls = 0
    private var waiter: CheckedContinuation<Void, Never>?
    func waitOnSecond() async { calls += 1; if calls == 2 { entered = true; await withCheckedContinuation { waiter = $0 } } }
    func release() { waiter?.resume(); waiter = nil }
}
