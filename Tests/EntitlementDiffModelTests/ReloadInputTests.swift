import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

@MainActor
final class ReloadInputTests: XCTestCase {
    func testReloadRereadsSameURLArchitectureAndInvalidatesReport() async throws {
        let reader = ReloadReader()
        let model = ComparisonModel(reader: reader, architecture: .x86_64)
        for side in ComparisonSide.allCases {
            let task = model.load(url(side.rawValue), side: side)
            let request = await reader.next()
            await reader.finish(request, value: 1)
            await task.value
        }
        XCTAssertNotNil(model.report)
        model.browser.filter = .unchanged
        model.browser.selection = model.browser.visibleRows.first?.id
        XCTAssertEqual(model.browser.selectedRow?.current, .integer(1))
        let task = try XCTUnwrap(model.reload(.previous))
        XCTAssertNil(model.report)
        XCTAssertTrue(model.browser.visibleRows.isEmpty)
        XCTAssertNil(model.browser.selection)
        XCTAssertTrue(model.previous.isLoading)
        XCTAssertNotNil(model.current.snapshot)
        let request = await reader.next()
        XCTAssertEqual(request.url, url("previous"))
        XCTAssertEqual(request.architecture, .x86_64)
        await reader.finish(request, value: 2)
        await task.value
        XCTAssertEqual(model.rows.first?.kind, .changed)
        XCTAssertEqual(model.previous.snapshot?.entitlements["value"], .integer(2))
        XCTAssertEqual(model.browser.count(.changed), 1)
        XCTAssertTrue(model.browser.visibleRows.isEmpty)
        model.browser.filter = .changed
        XCTAssertEqual(model.browser.visibleRows.first?.previous, .integer(2))
    }

    func testFailureRetainsURLForRetryAndSwapRetainsCorrectSource() async throws {
        let reader = ReloadReader()
        let model = ComparisonModel(reader: reader)
        let task = model.load(url("old"), side: .previous)
        let request = await reader.next()
        await reader.fail(request); await task.value
        XCTAssertTrue(model.canReload(.previous))
        XCTAssertNil(model.previous.snapshot)
        let retry = try XCTUnwrap(model.reload(.previous))
        let retried = await reader.next()
        XCTAssertEqual(retried.url, url("old"))
        await reader.finish(retried, value: 1); await retry.value
        let current = model.load(url("new"), side: .current)
        let currentRequest = await reader.next()
        await reader.finish(currentRequest, value: 2); await current.value
        XCTAssertTrue(model.swap())
        let swapped = try XCTUnwrap(model.reload(.previous))
        let swappedRequest = await reader.next()
        XCTAssertEqual(swappedRequest.url, url("new"))
        await reader.finish(swappedRequest, value: 3); await swapped.value
    }

    func testReloadBothStartsBothAndRequiresTwoLiveSelections() async {
        let reader = ReloadReader()
        let model = ComparisonModel(reader: reader)
        model.loadExample()
        XCTAssertFalse(model.canReloadBoth)
        XCTAssertTrue(model.reloadBoth().isEmpty)
        XCTAssertNil(model.reload(.previous))
        for side in ComparisonSide.allCases {
            let task = model.load(url(side.rawValue), side: side)
            let request = await reader.next()
            await reader.finish(request, value: 1); await task.value
        }
        let tasks = model.reloadBoth()
        XCTAssertEqual(tasks.count, 2)
        XCTAssertTrue(model.previous.isLoading && model.current.isLoading)
        XCTAssertNil(model.report)
        let a = await reader.next(), b = await reader.next()
        XCTAssertEqual(Set([a.url, b.url]), Set([url("previous"), url("current")]))
        await reader.finish(a, value: 2); await reader.finish(b, value: 3)
        for task in tasks { await task.value }
        XCTAssertNotNil(model.report)
        model.clear(.previous)
        XCTAssertFalse(model.canReloadBoth)
        XCTAssertTrue(model.reloadBoth().isEmpty)
    }

    func testLateReloadCannotRestoreReplacedSelection() async throws {
        let reader = ReloadReader()
        let model = ComparisonModel(reader: reader)
        let initial = model.load(url("old"), side: .previous)
        let a = await reader.next()
        let reload = try XCTUnwrap(model.reload(.previous))
        let b = await reader.next()
        let replacement = model.load(url("new"), side: .previous)
        let c = await reader.next()
        await reader.finish(c, value: 3); await replacement.value
        await reader.finish(b, value: 2); await reload.value
        await reader.finish(a, value: 1); await initial.value
        XCTAssertEqual(model.previous.snapshot?.sourceName, "new.app")
        XCTAssertEqual(model.previous.snapshot?.entitlements["value"], .integer(3))
    }

    func testClearAndArchitectureChangeSuppressLateReloads() async throws {
        for changeArchitecture in [false, true] {
            let reader = ReloadReader()
            let model = ComparisonModel(reader: reader, architecture: .arm64)
            let initial = model.load(url("old"), side: .previous)
            let a = await reader.next()
            let reload = try XCTUnwrap(model.reload(.previous))
            let b = await reader.next()
            if changeArchitecture { model.setArchitecture(.x86_64) } else { model.clear() }
            await reader.finish(b, value: 2); await reload.value
            await reader.finish(a, value: 1); await initial.value
            XCTAssertTrue(model.previous.isEmpty)
            XCTAssertNil(model.report)
            XCTAssertFalse(model.canReload(.previous))
            XCTAssertNil(model.reload(.previous))
        }
    }

    private func url(_ name: String) -> URL { URL(fileURLWithPath: "/synthetic/\(name).app") }
}

private actor ReloadReader: SnapshotReading {
    struct Request: Sendable { let id: UUID; let url: URL; let architecture: Architecture }
    private var queue: [Request] = []
    private var consumers: [CheckedContinuation<Request, Never>] = []
    private var completions: [UUID: CheckedContinuation<EntitlementSnapshot, any Error>] = [:]
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot {
        try await withCheckedThrowingContinuation { completion in
            let request = Request(id: UUID(), url: url, architecture: architecture)
            completions[request.id] = completion
            if consumers.isEmpty { queue.append(request) } else { consumers.removeFirst().resume(returning: request) }
        }
    }
    func next() async -> Request {
        if !queue.isEmpty { return queue.removeFirst() }
        return await withCheckedContinuation { consumers.append($0) }
    }
    func finish(_ request: Request, value: Int64) {
        completions.removeValue(forKey: request.id)?.resume(returning: .init(
            sourceName: request.url.lastPathComponent, signingIdentifier: "test", architecture: request.architecture,
            entitlements: .init(["value": .integer(value)])))
    }
    func fail(_ request: Request) {
        completions.removeValue(forKey: request.id)?.resume(throwing: Failure())
    }
    struct Failure: LocalizedError { var errorDescription: String? { "Temporarily unavailable" } }
}
