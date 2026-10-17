import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

final class ChangeNavigationTests: XCTestCase {
    private func browser() -> ComparisonBrowser {
        var result = ComparisonBrowser()
        result.filter = .allKeys
        result.replaceRows(EntitlementComparison(
            previous: .init(["a": .integer(1), "b": .boolean(true), "c": .integer(3), "d": .integer(4)]),
            current: .init(["a": .integer(2), "b": .boolean(true), "c": .integer(5), "e": .integer(6)])).rows)
        return result
    }
    func testStartsAtEitherEndSkipsUnchangedAndNeverWraps() throws {
        var subject = browser()
        XCTAssertEqual(subject.changePositionText, "Visible changes: 4")
        XCTAssertEqual(subject.moveToChange(.next), subject.visibleRows[0].id)
        XCTAssertNil(subject.changeTarget(.previous))
        XCTAssertEqual(subject.changePositionText, "Change 1 of 4 in this view")
        XCTAssertEqual(subject.moveToChange(.next), subject.visibleRows[2].id)
        subject.selection = subject.visibleRows[1].id // Unchanged b, between a and c.
        XCTAssertEqual(subject.changeTarget(.next), subject.visibleRows[2].id)
        XCTAssertEqual(subject.changeTarget(.previous), subject.visibleRows[0].id)
        subject.selection = nil
        XCTAssertEqual(subject.moveToChange(.previous), subject.visibleRows.last?.id)
        let last = subject.selection
        XCTAssertNil(subject.moveToChange(.next))
        XCTAssertEqual(subject.selection, last)
        XCTAssertEqual(subject.changePositionText, "Change 4 of 4 in this view")
    }
    func testSortAndFiltersUseCurrentVisibleOrderWithoutPreferenceChanges() {
        var subject = browser()
        subject.sortOrder = [.init(column: .key, order: .reverse)]
        let sort = subject.sortOrder
        XCTAssertEqual(subject.moveToChange(.next), subject.visibleRows[0].id)
        subject.filter = .changed
        subject.query = "c"
        XCTAssertNil(subject.selection)
        XCTAssertEqual(subject.moveToChange(.next), subject.visibleRows.first?.id)
        XCTAssertEqual(subject.selectedRow?.key, "c")
        XCTAssertNil(subject.changeTarget(.previous)); XCTAssertNil(subject.changeTarget(.next))
        XCTAssertEqual(subject.filter, .changed); XCTAssertEqual(subject.query, "c"); XCTAssertEqual(subject.sortOrder, sort)
        XCTAssertEqual(subject.count(.allKeys), 5); XCTAssertEqual(subject.count(.allChanges), 4)
        subject.filter = .unchanged; subject.query = ""
        XCTAssertNil(subject.changeTarget(.next)); XCTAssertNil(subject.changeTarget(.previous))
        XCTAssertEqual(subject.changePositionText, "Visible changes: 0")
    }
    func testReplacementRebuildsNavigationAndPreservesExactKeyIdentity() throws {
        var subject = browser()
        _ = subject.moveToChange(.next)
        let values = try EntitlementDictionary(entries: [.init(key: "é", value: .integer(Int64.max)), .init(key: "e\u{301}", value: .boolean(true))])
        subject.replaceRows(EntitlementComparison(previous: .init(), current: values).rows)
        XCTAssertNil(subject.selection)
        let first = subject.moveToChange(.next), second = subject.moveToChange(.next)
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(subject.selectedRow?.current, .integer(Int64.max))
        subject.replaceRows([])
        XCTAssertNil(subject.changeTarget(.next)); XCTAssertNil(subject.selection)
        XCTAssertEqual(subject.changePositionText, "Visible changes: 0")
    }
}
