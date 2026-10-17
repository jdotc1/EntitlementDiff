import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

@MainActor
final class BrowserRecoveryTests: XCTestCase {
    private func browser(old: EntitlementDictionary = .init(), new: EntitlementDictionary) -> ComparisonBrowser {
        var result = ComparisonBrowser()
        result.replaceRows(EntitlementComparison(previous: old, current: new).rows)
        result.sortOrder = [.init(column: .change, order: .reverse), .init(column: .key, order: .reverse)]
        return result
    }

    func testClearSearchPreservesCategorySortCountsAndDoesNotInventSelection() throws {
        var subject = browser(new: .init(["a": .boolean(true), "b": .integer(Int64.max)]))
        subject.filter = .added
        let sort = subject.sortOrder
        let selected = try XCTUnwrap(subject.visibleRows.first?.id)
        subject.selection = selected
        subject.query = "missing"
        XCTAssertNil(subject.selection)
        XCTAssertEqual(subject.recoveryGuidance?.action, .clearSearch)
        subject.recover(.clearSearch)
        XCTAssertEqual(subject.filter, .added)
        XCTAssertEqual(subject.sortOrder, sort)
        XCTAssertEqual(subject.count(.added), 2)
        XCTAssertEqual(subject.visibleRows.count, 2)
        XCTAssertNil(subject.selection)
        XCTAssertNil(subject.recoveryGuidance)
        subject.selection = selected
        subject.recover(.clearSearch) // Obsolete button after results are visible.
        XCTAssertEqual(subject.selection, selected)
    }

    func testEmptyCategoryAndCombinedRestrictionsRecoverAtomically() {
        var subject = browser(new: .init(["added": .integer(1)]))
        let sort = subject.sortOrder
        subject.filter = .removed
        XCTAssertEqual(subject.recoveryGuidance?.actionLabel, "Show All Changes")
        subject.query = "missing"
        XCTAssertEqual(subject.recoveryGuidance?.actionLabel, "Clear Search and Show All Changes")
        subject.recover(.clearSearch) // Not an appropriate current action.
        XCTAssertEqual(subject.query, "missing")
        subject.recover(.showAllChanges)
        XCTAssertEqual(subject.query, "")
        XCTAssertEqual(subject.filter, .allChanges)
        XCTAssertEqual(subject.sortOrder, sort)
        XCTAssertEqual(subject.visibleRows.map(\.key), ["added"])
        XCTAssertEqual(subject.count(.removed), 0)
    }

    func testNoChangesOffersAllKeysWithExactTypedAndUTF8Identity() throws {
        let values = try EntitlementDictionary(entries: [
            .init(key: "é", value: .integer(Int64.max)), .init(key: "e\u{301}", value: .boolean(true))
        ])
        var subject = browser(old: values, new: values)
        let sort = subject.sortOrder
        XCTAssertTrue(subject.recoveryGuidance?.title.contains("No entitlement-value changes") == true)
        XCTAssertEqual(subject.recoveryGuidance?.action, .showAllKeys)
        subject.query = "missing"
        XCTAssertEqual(subject.recoveryGuidance?.actionLabel, "Clear Search and Show All Keys")
        subject.recover(.showAllKeys)
        XCTAssertEqual(subject.sortOrder, sort)
        XCTAssertEqual(subject.visibleRows.count, 2)
        XCTAssertEqual(Set(subject.visibleRows.map(\.id)).count, 2)
        XCTAssertEqual(subject.count(.allChanges), 0)
        XCTAssertEqual(subject.count(.unchanged), 2)
        XCTAssertEqual(subject.visibleRows.first { $0.key.utf8.elementsEqual("é".utf8) }?.current, .integer(Int64.max))
        XCTAssertNil(subject.selection)
    }

    func testZeroKeysHasNoMisleadingRecoveryAndSourceReplacementRejectsOldAction() {
        var subject = browser(new: .init(["a": .integer(1)]))
        subject.query = "missing"
        XCTAssertEqual(subject.recoveryGuidance?.action, .clearSearch)
        subject.replaceRows([])
        XCTAssertEqual(subject.recoveryGuidance?.title, "No entitlement keys in this scope")
        XCTAssertNil(subject.recoveryGuidance?.action)
        subject.recover(.clearSearch)
        XCTAssertEqual(subject.query, "missing")
        XCTAssertEqual(subject.count(.allKeys), 0)
        XCTAssertFalse(subject.recoveryGuidance!.message.contains("read successfully"))
        XCTAssertNil(ComparisonBrowser().recoveryGuidance)
    }

    func testRecoveryPreservesCompleteSchemaOneReport() throws {
        let model = ComparisonModel(reader: RecoveryReader())
        model.loadExample()
        let report = try XCTUnwrap(model.report)
        let before = try report.jsonData()
        let revision = model.reportRevision
        model.browser.filter = .removed
        model.browser.query = "missing"
        let sort: [BrowserSort] = [.init(column: .key, order: .reverse)]
        model.browser.sortOrder = sort
        model.browser.recover(.clearSearch)
        XCTAssertEqual(model.browser.filter, .removed)
        XCTAssertEqual(model.browser.visibleRows.count, 1)
        XCTAssertEqual(model.browser.sortOrder, sort)
        XCTAssertEqual(try XCTUnwrap(model.report).jsonData(), before)
        let encoded = try XCTUnwrap(JSONSerialization.jsonObject(with: before) as? [String: Any])
        XCTAssertEqual(encoded["schemaVersion"] as? Int, 1)
        XCTAssertEqual(model.reportRevision, revision)
    }
}
private actor RecoveryReader: SnapshotReading {
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot { throw CancellationError() }
}
