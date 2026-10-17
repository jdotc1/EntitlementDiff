import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

final class ExactFindTests: XCTestCase {
    private var source: [EntitlementChange] {
        let pair = ExampleSnapshots.pair(architecture: .arm64)
        return EntitlementComparison(previous: pair.previous.entitlements, current: pair.current.entitlements).rows
    }
    func testVisibleMissingAndHiddenPreservePreferencesUntilExplicitReveal() throws {
        var browser = ComparisonBrowser(); browser.replaceRows(source)
        let parser = try XCTUnwrap(source.first { $0.key == "example.parser-version" })
        browser.sortOrder = [BrowserSort(column: .key, order: .reverse)]
        XCTAssertEqual(browser.findExactKey(parser.key), .found(parser.id))
        XCTAssertEqual(browser.selectedRow?.current, .integer(2))
        XCTAssertEqual(browser.findExactKey("EXAMPLE.PARSER-VERSION"), .missing)
        XCTAssertEqual(browser.selection, parser.id)
        browser.query = "parser"
        let unchanged = try XCTUnwrap(source.first { $0.kind == .unchanged })
        XCTAssertEqual(browser.findExactKey(unchanged.key), .hidden)
        XCTAssertEqual(browser.query, "parser")
        XCTAssertEqual(browser.filter, .allChanges)
        XCTAssertEqual(browser.selection, parser.id)
        XCTAssertEqual(browser.findExactKey(unchanged.key, revealHidden: true), .found(unchanged.id))
        XCTAssertEqual(browser.filter, .allKeys); XCTAssertEqual(browser.query, "")
        XCTAssertEqual(browser.sortOrder, [BrowserSort(column: .key, order: .reverse)])
        XCTAssertEqual(browser.count(.allKeys), 6); XCTAssertEqual(browser.count(.allChanges), 5)
        XCTAssertEqual(browser.selectedRow?.kind, .unchanged)
    }
    func testByteDistinctKeysWhitespaceEmptyAndSourceReplacement() throws {
        let values = try EntitlementDictionary(entries: [
            .init(key: "é", value: .integer(1)), .init(key: "e\u{301}", value: .integer(2)),
            .init(key: " key ", value: .integer(3)), .init(key: "", value: .boolean(false))
        ])
        var browser = ComparisonBrowser()
        browser.replaceRows(EntitlementComparison(previous: .init(), current: values).rows)
        let composed = browser.findExactKey("é"), id = browser.selection
        XCTAssertEqual(composed, .found(try XCTUnwrap(id)))
        _ = browser.findExactKey("e\u{301}")
        XCTAssertNotEqual(browser.selection, id)
        XCTAssertEqual(browser.selectedRow?.current, .integer(2))
        XCTAssertEqual(browser.findExactKey("key"), .missing)
        XCTAssertEqual(browser.findExactKey(" key "), .found(try XCTUnwrap(browser.visibleRows.first { $0.key == " key " }?.id)))
        XCTAssertEqual(browser.findExactKey(""), .found(""))
        browser.replaceRows([])
        XCTAssertEqual(browser.findExactKey("é", revealHidden: true), .missing)
        XCTAssertNil(browser.selection)
    }
    @MainActor func testExactFindDoesNotChangeCompleteReportOrSavedProvenance() throws {
        let pair = ExampleSnapshots.pair(architecture: .arm64)
        let saved = try SavedReport.parse(ComparisonReport(previous: pair.previous, current: pair.current).jsonData())
        let model = ComparisonModel(reader: UnusedFindReader())
        model.openSavedComparison(saved)
        let before = try XCTUnwrap(model.report).jsonData()
        let unchanged = try XCTUnwrap(model.rows.first { $0.kind == .unchanged })
        XCTAssertEqual(model.browser.findExactKey(unchanged.key), .hidden)
        _ = model.browser.findExactKey(unchanged.key, revealHidden: true)
        XCTAssertEqual(try model.report?.jsonData(), before)
        XCTAssertTrue(model.previous.snapshot?.isSavedBaseline == true)
        XCTAssertTrue(model.current.snapshot?.isSavedBaseline == true)
        XCTAssertTrue(model.selectedSourceURLs.isEmpty)
    }

}

private struct UnusedFindReader: SnapshotReading {
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot {
        throw CocoaError(.fileReadUnknown)
    }
}
