import XCTest
@testable import EntitlementDiffCore

final class InspectorAncestorTests: XCTestCase {
    func testDirectAncestorRestoresDictionaryPageHistoryAndClearsLookup() throws {
        let inner = EntitlementValue.dictionary(.init(["leaf": .array([.integer(1)])]))
        let entries = (0..<115).map { EntitlementEntry(key: String(format: "k%03d", $0), value: inner) }
        let value = EntitlementValue.dictionary(try .init(entries: entries))
        var nav = InspectorBranchNavigator(previous: value, current: value)
        nav.nextPage()
        let rootIDs = nav.rows.map(\.id)
        XCTAssertTrue(nav.enter(nav.rows[0].id))
        let parentID = nav.root.id
        XCTAssertTrue(nav.enter(nav.rows[0].id))
        let parent = try XCTUnwrap(nav.recentAncestors.first)
        XCTAssertEqual(parent.level, 1)
        XCTAssertTrue(nav.jump(to: parent))
        XCTAssertEqual(nav.root.id, parentID)
        XCTAssertTrue(nav.findExactChild("leaf"))
        let root = try XCTUnwrap(nav.rootAncestor)
        XCTAssertTrue(nav.jump(to: root))
        XCTAssertEqual(nav.offset, 50)
        XCTAssertEqual(nav.rows.map(\.id), rootIDs)
        XCTAssertNil(nav.exactChild)
        nav.previousPage(); XCTAssertEqual(nav.offset, 0)
        nav.nextPage(); XCTAssertEqual(nav.rows.map(\.id), rootIDs)
        XCTAssertFalse(nav.jump(to: parent))
        XCTAssertNil(nav.rootAncestor)
    }

    func testBoundedMenuAndStaleFrameIdentityWithUnicodeLabels() throws {
        var child = EntitlementValue.array([.integer(42)])
        for i in 0..<18 {
            child = .dictionary(try .init(entries: [.init(key: i % 2 == 0 ? "é" : "e\u{301}", value: child)]))
        }
        var nav = InspectorBranchNavigator(previous: nil, current: child)
        for _ in 0..<18 { XCTAssertTrue(nav.enter(nav.rows[0].id)) }
        XCTAssertEqual(nav.recentAncestors.count, 12)
        XCTAssertEqual(nav.recentAncestors.map(\.level), Array((6...17).reversed()))
        XCTAssertEqual(Set(nav.recentAncestors.map(\.id)).count, 12)
        let labels = nav.recentAncestors.map { Array($0.label.utf8) }
        XCTAssertTrue(labels.contains(Array("\"é\"".utf8)))
        XCTAssertTrue(labels.contains(Array("\"e\u{301}\"".utf8)))
        let stale = try XCTUnwrap(nav.recentAncestors.first)
        let root = try XCTUnwrap(nav.rootAncestor)
        XCTAssertTrue(nav.jump(to: root))
        for _ in 0..<18 { XCTAssertTrue(nav.enter(nav.rows[0].id)) }
        XCTAssertFalse(nav.jump(to: stale))
        let unchangedID = nav.root.id
        var replacement = InspectorBranchNavigator(previous: nil, current: child)
        XCTAssertFalse(replacement.jump(to: root))
        XCTAssertEqual(nav.root.id, unchangedID)
    }

    func testArrayAncestorRetainsDirectIndexCursor() throws {
        let inner = EntitlementValue.array([.array([.integer(1)])])
        var nav = InspectorBranchNavigator(previous: nil, current: .array(Array(repeating: inner, count: 120)))
        XCTAssertTrue(nav.goToArrayIndex(93))
        XCTAssertTrue(nav.enter(nav.rows[0].id))
        XCTAssertTrue(nav.enter(nav.rows[0].id))
        XCTAssertTrue(nav.jump(to: try XCTUnwrap(nav.rootAncestor)))
        XCTAssertEqual(nav.offset, 93)
        XCTAssertEqual(nav.rows[0].id, "root/i93")
        XCTAssertFalse(nav.canGoBack)
    }
}
