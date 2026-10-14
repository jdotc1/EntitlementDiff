import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

final class ComparisonBrowserTests: XCTestCase {
    private var rows: [EntitlementChange] {
        let pair = ExampleSnapshots.pair(architecture: .arm64)
        return EntitlementComparison(previous: pair.previous.entitlements, current: pair.current.entitlements).rows
    }
    func testFiltersCountsAndSearchDoNotAlterComparison() throws {
        var browser = ComparisonBrowser()
        let source = rows
        XCTAssertEqual(browser.visibleRows(in: source).count, 5)
        for (filter, count) in [(BrowserFilter.added, 1), (.removed, 1), (.changed, 3), (.unchanged, 1)] {
            browser.filter = filter
            XCTAssertEqual(browser.visibleRows(in: source).count, count)
            XCTAssertEqual(browser.count(filter, in: source), count)
        }
        browser.filter = .changed
        browser.query = "PARSER"
        XCTAssertEqual(browser.visibleRows(in: source).map(\.key), ["example.parser-version"])
        XCTAssertEqual(browser.count(.changed, in: source), 3)
        XCTAssertEqual(source.count, 6)
    }
    func testSortingAndResetPreserveOnlyVisibleSelection() {
        var browser = ComparisonBrowser()
        let source = rows
        let selected = source.first { $0.key == "example.parser-version" }!.id
        browser.selection = selected
        browser.sortOrder = [BrowserSort(column: .key, order: .reverse)]
        let descending = browser.visibleRows(in: source)
        browser.reconcileSelection(in: descending)
        XCTAssertEqual(browser.selection, selected)
        XCTAssertEqual(descending.map(\.key), descending.map(\.key).sorted { $1.utf8.lexicographicallyPrecedes($0.utf8) })
        browser.filter = .removed
        browser.reconcileSelection(in: browser.visibleRows(in: source))
        XCTAssertNil(browser.selection)
        browser.query = "missing"
        browser.reset()
        XCTAssertTrue(browser.isDefault)
        XCTAssertEqual(browser.visibleRows(in: source).count, 5)
        XCTAssertNil(browser.selection)
    }
    func testChangeSortAndByteDistinctUnicodeTies() throws {
        let keys = ["é", "e\u{301}", "z"]
        let dictionary = try EntitlementDictionary(entries: keys.map { .init(key: $0, value: .boolean(true)) })
        let unicodeRows = EntitlementComparison(previous: .init([:]), current: dictionary).rows
        var browser = ComparisonBrowser()
        browser.sortOrder = [BrowserSort(column: .change)]
        let sorted = browser.visibleRows(in: unicodeRows)
        XCTAssertEqual(Set(sorted.map(\.id)).count, 3)
        XCTAssertEqual(sorted.map { Array($0.key.utf8) }, keys.sorted { $0.utf8.lexicographicallyPrecedes($1.utf8) }.map { Array($0.utf8) })
        let mixed = browser.visibleRows(in: rows)
        XCTAssertEqual(mixed.map(\.kind), [.added, .removed, .changed, .changed, .changed])
        browser.sortOrder = [BrowserSort(column: .change, order: .reverse)]
        XCTAssertEqual(browser.visibleRows(in: rows).map(\.kind), [.changed, .changed, .changed, .removed, .added])
        browser.selection = sorted[0].id
        browser.reconcileSelection(in: [])
        XCTAssertNil(browser.selection)
    }
}
