import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

final class LeafPageNavigationTests: XCTestCase {
    func testInvalidJumpsPreservePageAndEditsRecover() {
        var state = LeafPageNavigation()
        state.input = "7"; state.go(pageCount: 10)
        XCTAssertEqual(state.index, 6)
        for invalid in ["", "0", "11", "-1", "+2", "1.5", " 2", "2 ", "1e1", "２", String(repeating: "9", count: 40)] {
            state.input = invalid; state.go(pageCount: 10)
            XCTAssertTrue(state.isInvalid, invalid)
            XCTAssertEqual(state.index, 6, invalid)
        }
        state.input = "01"
        XCTAssertFalse(state.isInvalid)
        state.go(pageCount: 10)
        XCTAssertEqual(state.index, 0)
        XCTAssertEqual(state.input, "1")
        state.select(9, pageCount: 10)
        XCTAssertEqual(state.input, "10")
    }

    func testIndependentMiddlePagesUseExistingDocumentAndFreshState() throws {
        let old = try LeafValueDocument(leaf: XCTUnwrap(InspectorLeaf(.string(String(repeating: "A", count: 512) + "middle" + String(repeating: "B", count: 1024)))))
        let current = try LeafValueDocument(leaf: XCTUnwrap(InspectorLeaf(.data(Data(repeating: 42, count: 2305)))))
        var previousPages = LeafPageNavigation(), currentPages = LeafPageNavigation()
        previousPages.input = "2"; previousPages.go(pageCount: old.pageCount)
        XCTAssertTrue(old.text(onPage: previousPages.index).contains("middle"))
        XCTAssertEqual(currentPages.index, 0)
        currentPages.input = "3"; currentPages.go(pageCount: current.pageCount)
        XCTAssertEqual(previousPages.index, 1)
        XCTAssertEqual(currentPages.index, 2)
        XCTAssertEqual(current.text(onPage: currentPages.index), Data(repeating: 42, count: 768).base64EncodedString())
        let reopened = LeafPageNavigation()
        XCTAssertEqual(reopened.index, 0)
        XCTAssertEqual(reopened.input, "1")
        XCTAssertFalse(reopened.isInvalid)
    }
}
