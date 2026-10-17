import AppKit
import XCTest
import EntitlementDiffCore
import EntitlementDiffModel
@testable import EntitlementDiffApp

@MainActor
final class FinderReportTests: XCTestCase {
    private func saved() throws -> SavedReport {
        let pair = ExampleSnapshots.pair(architecture: .arm64)
        return try SavedReport.parse(ComparisonReport(previous: pair.previous, current: pair.current).jsonData())
    }
    private func model() -> ComparisonModel {
        let result = ComparisonModel(reader: FinderUnusedReader())
        result.loadExample(structured: true)
        return result
    }
    func testOpenAndCancelLeaveCurrentSessionUntouchedUntilExplicitAdoption() async throws {
        let model = model(), incoming = try saved()
        let actions = AppActions(model: model, readSavedReport: { _ in incoming })
        let revision = model.reportRevision, before = try XCTUnwrap(model.report).jsonData()
        let task = try XCTUnwrap(actions.receiveSavedReportURLs([URL(fileURLWithPath: "/tmp/report.json")]))
        await task.value
        XCTAssertNotNil(actions.savedReport)
        XCTAssertEqual(model.reportRevision, revision)
        XCTAssertEqual(try model.report?.jsonData(), before)
        actions.savedReport = nil // Same non-mutating Cancel used by the existing sheet.
        XCTAssertEqual(try model.report?.jsonData(), before)
        let second = try XCTUnwrap(actions.receiveSavedReportURLs([URL(fileURLWithPath: "/tmp/report.json")]))
        await second.value
        actions.openSavedComparison()
        XCTAssertNotEqual(model.reportRevision, revision)
        XCTAssertTrue(model.previous.snapshot?.isSavedBaseline == true)
        XCTAssertTrue(model.current.snapshot?.isSavedBaseline == true)
        XCTAssertEqual(model.rows.count, 6)
        XCTAssertTrue(model.selectedSourceURLs.isEmpty)
    }
    func testBusyReadingAndReviewRejectIncomingWithoutReplacingReview() async throws {
        let incoming = try saved(), gate = FinderReadGate()
        let model = model()
        let actions = AppActions(model: model, readSavedReport: { _ in await gate.read() })
        let task = try XCTUnwrap(actions.receiveSavedReportURLs([URL(fileURLWithPath: "/tmp/first.json")]))
        await gate.started()
        XCTAssertTrue(actions.isReadingSavedReport)
        XCTAssertNil(actions.receiveSavedReportURLs([URL(fileURLWithPath: "/tmp/second.json")]))
        XCTAssertTrue(actions.statusMessage.contains("Finish the current action"))
        await gate.finish(incoming); await task.value
        let reviewID = actions.savedReport?.id
        XCTAssertNil(actions.receiveSavedReportURLs([URL(fileURLWithPath: "/tmp/second.json")]))
        XCTAssertEqual(actions.savedReport?.id, reviewID)
        XCTAssertNil(actions.errorMessage)
        actions.savedReport = nil
        actions.isFindingEntitlement = true
        XCTAssertNil(actions.receiveSavedReportURLs([URL(fileURLWithPath: "/tmp/second.json")]))
        actions.isFindingEntitlement = false
        actions.errorMessage = "Existing error"
        XCTAssertNil(actions.receiveSavedReportURLs([URL(fileURLWithPath: "/tmp/second.json")]))
        XCTAssertEqual(actions.errorMessage, "Existing error")
    }
    func testMalformedDirectoryOversizedAndUnsupportedSchemaPreserveSession() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let bad = root.appendingPathComponent("Bad.json"), schema = root.appendingPathComponent("Schema.json"), large = root.appendingPathComponent("Large.json")
        try Data("{".utf8).write(to: bad)
        try Data("{\"schemaVersion\":2}".utf8).write(to: schema)
        try Data(repeating: 32, count: SavedReport.maximumBytes + 1).write(to: large)
        let model = model(), actions = AppActions(model: model)
        let before = try XCTUnwrap(model.report).jsonData(), revision = model.reportRevision
        for url in [bad, schema, large, root] {
            actions.errorMessage = nil
            let task = try XCTUnwrap(actions.receiveSavedReportURLs([url])); await task.value
            XCTAssertNotNil(actions.errorMessage)
            XCTAssertNil(actions.savedReport)
            XCTAssertFalse(actions.isReadingSavedReport)
            XCTAssertEqual(try model.report?.jsonData(), before)
            XCTAssertEqual(model.reportRevision, revision)
        }
    }
    func testRejectsMultipleRemoteAndEmptyRequestsBeforeReading() {
        let model = model(), actions = AppActions(model: model)
        let a = URL(fileURLWithPath: "/tmp/a.json")
        for urls in [[], [a, a], [URL(string: "https://example.invalid/report.json")!]] {
            actions.errorMessage = nil
            XCTAssertNil(actions.receiveSavedReportURLs(urls))
            XCTAssertNotNil(actions.errorMessage)
            XCTAssertFalse(actions.isReadingSavedReport)
        }
    }
    func testDelegateRetainsOnlyFirstBoundedEarlyLaunchRequest() async throws {
        let incoming = try saved(), model = model()
        let actions = AppActions(model: model, readSavedReport: { _ in incoming })
        let delegate = AppDelegate()
        let a = URL(fileURLWithPath: "/tmp/a.json")
        delegate.application(NSApplication.shared, open: [a, a, a])
        delegate.application(NSApplication.shared, open: [a])
        delegate.configure(actions: actions)
        XCTAssertNotNil(actions.errorMessage) // First multi-file event rejected, second never queued.
        XCTAssertNil(actions.savedReport)
        actions.errorMessage = nil
        delegate.application(NSApplication.shared, open: [a])
        while actions.isReadingSavedReport { await Task.yield() }
        XCTAssertNotNil(actions.savedReport)
    }
}
private struct FinderUnusedReader: SnapshotReading {
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot { throw CancellationError() }
}
private actor FinderReadGate {
    private var continuation: CheckedContinuation<SavedReport, Never>?
    private var waiting: CheckedContinuation<Void, Never>?
    func read() async -> SavedReport {
        await withCheckedContinuation { continuation in
            self.continuation = continuation; waiting?.resume(); waiting = nil
        }
    }
    func started() async {
        if continuation != nil { return }
        await withCheckedContinuation { waiting = $0 }
    }
    func finish(_ report: SavedReport) { continuation?.resume(returning: report); continuation = nil }
}
