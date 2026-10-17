import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

final class ComparisonBrowserTests: XCTestCase {
    private var rows: [EntitlementChange] {
        let pair = ExampleSnapshots.pair(architecture: .arm64)
        return EntitlementComparison(previous: pair.previous.entitlements, current: pair.current.entitlements).rows
    }
    func testAllKeysIncludesEveryKindWhileDefaultAndResetRemainAllChanges() throws {
        var browser = ComparisonBrowser()
        let source = rows
        browser.replaceRows(source)
        XCTAssertEqual(browser.filter, .allChanges)
        XCTAssertEqual(browser.visibleRows.count, 5)
        browser.filter = .allKeys
        XCTAssertEqual(browser.visibleRows.count, 6)
        XCTAssertEqual(browser.count(.allKeys), 6)
        XCTAssertEqual(browser.count(.allKeys, in: source), 6)
        XCTAssertEqual(browser.visibleRows(in: source).map(\.id), browser.visibleRows.map(\.id))
        XCTAssertFalse(browser.isDefault)
        browser.sortOrder = [BrowserSort(column: .change)]
        XCTAssertEqual(browser.visibleRows.map(\.kind), [.added, .removed, .changed, .changed, .changed, .unchanged])
        let unchanged = try XCTUnwrap(source.first { $0.kind == .unchanged })
        browser.selection = unchanged.id
        browser.query = unchanged.key
        XCTAssertEqual(browser.visibleRows.map(\.id), [unchanged.id])
        XCTAssertEqual(browser.selectedRow?.id, unchanged.id)
        XCTAssertEqual(browser.count(.allKeys), 6)
        XCTAssertEqual(browser.count(.allChanges), 5)
        browser.reset()
        XCTAssertTrue(browser.isDefault)
        XCTAssertEqual(browser.filter, .allChanges)
        XCTAssertEqual(browser.visibleRows.count, 5)
        XCTAssertNil(browser.selection)
        XCTAssertEqual(source.count, 6)
    }

    func testAllKeysRefreshesCountsAndRetainsByteDistinctUnchangedKeys() throws {
        var browser = ComparisonBrowser()
        browser.filter = .allKeys
        XCTAssertEqual(browser.count(.allKeys), 0)
        let values = try EntitlementDictionary(entries: [
            .init(key: "é", value: .integer(1)), .init(key: "e\u{301}", value: .integer(2))
        ])
        browser.replaceRows(EntitlementComparison(previous: values, current: values).rows)
        XCTAssertEqual(browser.count(.allKeys), 2)
        XCTAssertEqual(browser.count(.allChanges), 0)
        XCTAssertEqual(Set(browser.visibleRows.map(\.id)).count, 2)
        XCTAssertEqual(browser.visibleRows.map { Array($0.key.utf8) }, values.entries.map { Array($0.key.utf8) })
        browser.selection = browser.visibleRows[0].id
        browser.replaceRows([])
        XCTAssertEqual(browser.count(.allKeys), 0)
        XCTAssertTrue(browser.visibleRows.isEmpty)
        XCTAssertNil(browser.selection)
    }

    func testFiltersCountsAndSearchDoNotAlterComparison() throws {
        var browser = ComparisonBrowser()
        let source = rows
        browser.replaceRows(source)
        XCTAssertEqual(browser.visibleRows.count, 5)
        for (filter, count) in [(BrowserFilter.added, 1), (.removed, 1), (.changed, 3), (.unchanged, 1)] {
            browser.filter = filter
            XCTAssertEqual(browser.visibleRows.count, count)
            XCTAssertEqual(browser.count(filter), count)
        }
        browser.filter = .changed
        browser.query = "PARSER"
        XCTAssertEqual(browser.visibleRows.map(\.key), ["example.parser-version"])
        XCTAssertEqual(browser.count(.changed), 3)
        XCTAssertEqual(source.count, 6)
    }
    func testSortingAndResetPreserveOnlyVisibleSelection() {
        var browser = ComparisonBrowser()
        let source = rows
        browser.replaceRows(source)
        let selected = source.first { $0.key == "example.parser-version" }!.id
        browser.selection = selected
        browser.sortOrder = [BrowserSort(column: .key, order: .reverse)]
        let descending = browser.visibleRows
        XCTAssertEqual(browser.selection, selected)
        XCTAssertEqual(browser.selectedRow?.id, selected)
        XCTAssertEqual(descending.map(\.key), descending.map(\.key).sorted { $1.utf8.lexicographicallyPrecedes($0.utf8) })
        browser.filter = .removed
        XCTAssertNil(browser.selection)
        XCTAssertNil(browser.selectedRow)
        browser.query = "missing"
        browser.reset()
        XCTAssertTrue(browser.isDefault)
        XCTAssertEqual(browser.visibleRows.count, 5)
        XCTAssertNil(browser.selection)
    }
    func testChangeSortAndByteDistinctUnicodeTies() throws {
        let keys = ["é", "e\u{301}", "z"]
        let dictionary = try EntitlementDictionary(entries: keys.map { .init(key: $0, value: .boolean(true)) })
        let unicodeRows = EntitlementComparison(previous: .init([:]), current: dictionary).rows
        var browser = ComparisonBrowser()
        browser.replaceRows(unicodeRows)
        browser.sortOrder = [BrowserSort(column: .change)]
        let sorted = browser.visibleRows
        XCTAssertEqual(Set(sorted.map(\.id)).count, 3)
        XCTAssertEqual(sorted.map { Array($0.key.utf8) }, keys.sorted { $0.utf8.lexicographicallyPrecedes($1.utf8) }.map { Array($0.utf8) })
        browser.replaceRows(rows)
        let mixed = browser.visibleRows
        XCTAssertEqual(mixed.map(\.kind), [.added, .removed, .changed, .changed, .changed])
        browser.sortOrder = [BrowserSort(column: .change, order: .reverse)]
        XCTAssertEqual(browser.visibleRows.map(\.kind), [.changed, .changed, .changed, .removed, .added])
        browser.selection = sorted[0].id
        browser.replaceRows([])
        XCTAssertNil(browser.selection)
    }

    func testReplacementWithSameIDsRefreshesSelectedValueAndCounts() throws {
        var browser = ComparisonBrowser()
        let original = EntitlementDictionary(["key": .integer(1)])
        browser.replaceRows(EntitlementComparison(previous: .init(), current: original).rows)
        let id = try XCTUnwrap(browser.visibleRows.first?.id)
        browser.selection = id
        browser.replaceRows(EntitlementComparison(previous: original, current: .init(["key": .integer(2)])).rows)
        XCTAssertEqual(browser.selection, id)
        XCTAssertEqual(browser.selectedRow?.current, .integer(2))
        XCTAssertEqual(browser.count(.added), 0)
        XCTAssertEqual(browser.count(.changed), 1)
        browser.replaceRows(EntitlementComparison(previous: original, current: original).rows)
        XCTAssertTrue(browser.visibleRows.isEmpty)
        XCTAssertNil(browser.selection)
        XCTAssertNil(browser.selectedRow)
        XCTAssertEqual(browser.count(.unchanged), 1)
        browser.filter = .unchanged
        XCTAssertEqual(browser.visibleRows.first?.current, .integer(1))
        browser.replaceRows([])
        XCTAssertTrue(BrowserFilter.allCases.allSatisfy { browser.count($0) == 0 })
    }

    func testStatelessHelpersPreserveCallerManagedSelectionUntilReconciliation() throws {
        var browser = ComparisonBrowser()
        let source = rows
        let selected = try XCTUnwrap(source.first { $0.key == "example.parser-version" }?.id)
        browser.selection = selected
        browser.sortOrder = [BrowserSort(column: .key, order: .reverse)]
        browser.query = "parser"
        browser.filter = .changed
        browser.reconcileSelection(in: browser.visibleRows(in: source))
        XCTAssertEqual(browser.selection, selected)
        XCTAssertEqual(browser.count(.changed, in: source), 3)
        browser.reset()
        XCTAssertEqual(browser.selection, selected)
        browser.filter = .removed
        XCTAssertEqual(browser.selection, selected)
        browser.reconcileSelection(in: browser.visibleRows(in: source))
        XCTAssertNil(browser.selection)
    }
}
