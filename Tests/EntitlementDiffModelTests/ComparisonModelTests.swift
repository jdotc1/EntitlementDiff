import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

@MainActor
final class ComparisonModelTests: XCTestCase {
    func testReleasingModelCancelsOutstandingTask() async {
        let reader = ControlledReader()
        var model: ComparisonModel? = ComparisonModel(reader: reader, architecture: .arm64)
        #if compiler(>=6.4)
        weak let weakModel = model
        #else
        weak var weakModel = model
        #endif
        let task = model!.load(url("Old.app"), side: .previous)
        let request = await reader.next()
        model = nil
        XCTAssertNil(weakModel)
        XCTAssertTrue(task.isCancelled)
        await reader.succeed(request, snapshot: snapshot("Old.app", value: true))
        await task.value
    }

    func testTwoSuccessfulLoadsCreateComparison() async {
        let reader = ControlledReader()
        let subject = ComparisonModel(reader: reader, architecture: .arm64)
        XCTAssertNil(subject.report)
        let old = subject.load(url("Old.app"), side: .previous)
        let oldRequest = await reader.next()
        let new = subject.load(url("New.app"), side: .current)
        let newRequest = await reader.next()
        await reader.succeed(oldRequest, snapshot: snapshot("Old.app", value: false))
        await old.value
        XCTAssertNil(subject.report)
        await reader.succeed(newRequest, snapshot: snapshot("New.app", value: true))
        await new.value
        XCTAssertEqual(subject.rows.count, 1)
        XCTAssertEqual(subject.rows.first?.kind, .changed)
        XCTAssertNotNil(subject.report)
    }

    func testFailureNeverBecomesEmptyDictionary() async {
        let reader = ControlledReader()
        let model = ComparisonModel(reader: reader, architecture: .arm64)
        let task = model.load(url("Broken.app"), side: .previous)
        let request = await reader.next()
        await reader.fail(request)
        await task.value
        XCTAssertNil(model.previous.snapshot)
        XCTAssertNotNil(model.previous.errorMessage)
        XCTAssertNil(model.report)
    }

    func testLateSupersededReadCannotReplaceNewSelection() async {
        let reader = ControlledReader()
        let model = ComparisonModel(reader: reader, architecture: .arm64)
        let first = model.load(url("Old.app"), side: .previous)
        let firstRequest = await reader.next()
        let second = model.load(url("New.app"), side: .previous)
        let secondRequest = await reader.next()
        await reader.succeed(secondRequest, snapshot: snapshot("New.app", value: true))
        await second.value
        await reader.succeed(firstRequest, snapshot: snapshot("Old.app", value: false))
        await first.value
        XCTAssertEqual(model.previous.snapshot?.sourceName, "New.app")
    }

    func testClearInvalidatesPendingResult() async {
        let reader = ControlledReader()
        let subject = ComparisonModel(reader: reader, architecture: .arm64)
        let task = subject.load(url("Old.app"), side: .previous)
        let request = await reader.next()
        subject.clear()
        await reader.succeed(request, snapshot: snapshot("Old.app", value: false))
        await task.value
        XCTAssertFalse(subject.hasInputs)
        XCTAssertNil(subject.report)
    }

    func testChangingArchitectureClearsBothAndDiscardsPendingResult() async {
        let reader = ControlledReader()
        let model = ComparisonModel(reader: reader, architecture: .arm64)
        model.loadExample()
        let task = model.load(url("Old.app"), side: .previous)
        let request = await reader.next()
        model.setArchitecture(.x86_64)
        await reader.succeed(request, snapshot: snapshot("Old.app", value: false))
        await task.value
        XCTAssertEqual(model.architecture, .x86_64)
        XCTAssertFalse(model.hasInputs)
        XCTAssertNil(model.report)
    }

    func testReplacingInputRemovesPreviouslyExportableReportImmediately() async {
        let reader = ControlledReader()
        let model = ComparisonModel(reader: reader, architecture: .arm64)
        model.loadExample()
        XCTAssertNotNil(model.report)
        let task = model.load(url("Replacement.app"), side: .previous)
        let request = await reader.next()
        XCTAssertNil(model.report)
        XCTAssertTrue(model.rows.isEmpty)
        XCTAssertTrue(model.previous.isLoading)
        XCTAssertFalse(model.canSwap)
        await reader.fail(request)
        await task.value
        XCTAssertNil(model.report)
    }

    func testExampleDiscardsOutstandingLiveRead() async {
        let reader = ControlledReader()
        let model = ComparisonModel(reader: reader, architecture: .arm64)
        let task = model.load(url("Old.app"), side: .previous)
        let request = await reader.next()
        model.loadExample()
        await reader.succeed(request, snapshot: snapshot("Old.app", value: true))
        await task.value
        XCTAssertEqual(model.previous.snapshot?.origin, .syntheticExample)
        XCTAssertEqual(model.current.snapshot?.origin, .syntheticExample)
        XCTAssertNotNil(model.report)
    }

    func testSwapReversesAddedAndRemoved() {
        let model = ComparisonModel(reader: ControlledReader(), architecture: .arm64)
        model.loadExample()
        let before = model.report?.previous.sourceName
        let addedKeys = model.rows.filter { $0.kind == .added }.map(\.key)
        let selected = model.rows.first { $0.key == "example.parser-version" }!.id
        model.browser.selection = selected
        XCTAssertTrue(model.swap())
        XCTAssertEqual(model.report?.current.sourceName, before)
        XCTAssertEqual(model.rows.filter { $0.kind == .removed }.map(\.key), addedKeys)
        XCTAssertEqual(model.browser.selection, selected)
        XCTAssertEqual(model.browser.selectedRow?.previous, .integer(2))
        XCTAssertEqual(model.browser.selectedRow?.current, .integer(1))
        XCTAssertEqual(model.browser.count(.allChanges), model.report?.changes.count)
    }

    func testBrowserProjectionInvalidatesWithoutChangingReportContents() async throws {
        let reader = ControlledReader()
        let model = ComparisonModel(reader: reader, architecture: .arm64)
        model.loadExample()
        let report = try XCTUnwrap(model.report)
        let json = try report.jsonData()
        model.browser.query = "parser"
        model.browser.selection = model.browser.visibleRows.first?.id
        XCTAssertEqual(model.browser.selectedRow?.current, .integer(2))
        XCTAssertEqual(model.browser.count(.allChanges), 5)
        XCTAssertEqual(model.rows.count, 6)
        XCTAssertEqual(try model.report?.jsonData(), json)
        let task = model.load(url("Replacement.app"), side: .previous)
        let request = await reader.next()
        XCTAssertNil(model.report)
        XCTAssertTrue(model.browser.visibleRows.isEmpty)
        XCTAssertNil(model.browser.selectedRow)
        XCTAssertNil(model.browser.selection)
        XCTAssertEqual(model.browser.count(.allChanges), 0)
        model.setArchitecture(.x86_64)
        await reader.succeed(request, snapshot: snapshot("Replacement.app", value: true))
        await task.value
        XCTAssertNil(model.report)
        XCTAssertTrue(model.browser.visibleRows.isEmpty)
        XCTAssertEqual(model.browser.query, "parser")
    }

    func testWrongArchitectureFromReaderIsRejected() async {
        let reader = ControlledReader()
        let model = ComparisonModel(reader: reader, architecture: .arm64)
        let task = model.load(url("Old.app"), side: .previous)
        let request = await reader.next()
        let wrong = EntitlementSnapshot(sourceName: "Old.app", signingIdentifier: "test", architecture: .x86_64, entitlements: .init())
        await reader.succeed(request, snapshot: wrong)
        await task.value
        XCTAssertNotNil(model.previous.errorMessage)
        XCTAssertNil(model.report)
    }

    func testExplicitTaskCancellationLeavesNoLoadingOrReport() async {
        let reader = ControlledReader()
        let model = ComparisonModel(reader: reader, architecture: .arm64)
        let task = model.load(url("Old.app"), side: .previous)
        let request = await reader.next()
        task.cancel()
        await reader.succeed(request, snapshot: snapshot("Old.app", value: true))
        await task.value
        XCTAssertFalse(model.previous.isLoading)
        XCTAssertNil(model.previous.snapshot)
        XCTAssertNil(model.report)
    }

    private func url(_ name: String) -> URL { URL(fileURLWithPath: "/synthetic/" + name) }
    private func snapshot(_ name: String, value: Bool) -> EntitlementSnapshot {
        .init(sourceName: name, signingIdentifier: "test", architecture: .arm64, entitlements: .init(["key": .boolean(value)]))
    }
}

private actor ControlledReader: SnapshotReading {
    struct Request: Sendable { let id: UUID; let url: URL; let architecture: Architecture }
    private var queued: [Request] = []
    private var consumers: [CheckedContinuation<Request, Never>] = []
    private var completions: [UUID: CheckedContinuation<EntitlementSnapshot, any Error>] = [:]

    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            let request = Request(id: UUID(), url: url, architecture: architecture)
            completions[request.id] = continuation
            if consumers.isEmpty { queued.append(request) }
            else { consumers.removeFirst().resume(returning: request) }
        }
    }
    func next() async -> Request {
        if !queued.isEmpty { return queued.removeFirst() }
        return await withCheckedContinuation { consumers.append($0) }
    }
    func succeed(_ request: Request, snapshot: EntitlementSnapshot) {
        completions.removeValue(forKey: request.id)?.resume(returning: snapshot)
    }
    func fail(_ request: Request) {
        completions.removeValue(forKey: request.id)?.resume(throwing: SyntheticFailure())
    }
    struct SyntheticFailure: LocalizedError {
        var errorDescription: String? { "Synthetic read failure" }
    }
}
