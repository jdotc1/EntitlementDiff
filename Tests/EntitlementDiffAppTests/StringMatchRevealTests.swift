import AppKit
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class StringMatchRevealTests: XCTestCase {
    func testNativeViewportDoesNotScrollHorizontallyToRevealMatch() throws {
        let source = String(repeating: "\u{0001}", count: 400) + "target" + String(repeating: "x", count: 60) + "target"
        let doc = try LeafValueDocument(leaf: XCTUnwrap(InspectorLeaf(.string(source))))
        let page = try XCTUnwrap(doc.stringPage(onPage: 0, matching: 466..<472))
        let scroll = HighlightedStringPageView.makeScrollView()
        scroll.frame = NSRect(x: 0, y: 0, width: 300, height: 120)
        scroll.layoutSubtreeIfNeeded()
        let text = try XCTUnwrap(scroll.documentView as? HighlightedStringPageView.PageTextView)
        HighlightedStringPageView.Coordinator().update(text, page: page, pageIndex: 0, revision: UUID())
        text.layoutSubtreeIfNeeded()
        XCTAssertEqual(scroll.contentView.bounds.origin.x, 0, accuracy: 0.1)
        XCTAssertLessThanOrEqual(text.frame.width, scroll.contentSize.width + 0.1)
    }

    func testSamePageRevisionRevealsNewExactRangeAndClearDropsPendingWork() throws {
        let doc = try LeafValueDocument(leaf: XCTUnwrap(InspectorLeaf(.string("target target"))))
        let first = try XCTUnwrap(doc.stringPage(onPage: 0, matching: 0..<6))
        let second = try XCTUnwrap(doc.stringPage(onPage: 0, matching: 7..<13))
        let text = HighlightedStringPageView.PageTextView(frame: .zero)
        let coordinator = HighlightedStringPageView.Coordinator()
        let revision = UUID()
        coordinator.update(text, page: first, pageIndex: 0, revision: revision)
        XCTAssertEqual(text.pendingReveal, first.highlight)
        text.pendingReveal = nil
        coordinator.update(text, page: first, pageIndex: 0, revision: revision)
        XCTAssertNil(text.pendingReveal)
        coordinator.update(text, page: second, pageIndex: 0, revision: UUID())
        XCTAssertEqual(text.pendingReveal, second.highlight)
        let color = text.textStorage?.attribute(.backgroundColor, at: try XCTUnwrap(second.highlight).location, effectiveRange: nil) as? NSColor
        XCTAssertEqual(color, .selectedTextBackgroundColor)
        XCTAssertEqual(text.textStorage?.attribute(.foregroundColor, at: try XCTUnwrap(second.highlight).location, effectiveRange: nil) as? NSColor, .selectedTextColor)
        XCTAssertNil(text.textStorage?.attribute(.backgroundColor, at: 1, effectiveRange: nil))
        coordinator.update(text, page: try XCTUnwrap(doc.stringPage(onPage: 0, matching: nil)), pageIndex: 0, revision: UUID())
        XCTAssertNil(text.pendingReveal)
        XCTAssertNil(text.textStorage?.attribute(.backgroundColor, at: 8, effectiveRange: nil))
    }
}
