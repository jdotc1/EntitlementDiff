import AppKit
import SwiftUI
import EntitlementDiffCore

/// Receives only one bounded escaped page. Match styling never edits source or clipboard values.
struct HighlightedStringPageView: NSViewRepresentable {
    let page: LeafValueDocument.StringPage
    let pageIndex: Int
    let revealRevision: UUID?
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> NSScrollView { Self.makeScrollView() }
    static func makeScrollView() -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        let text = PageTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        text.isEditable = false
        text.isSelectable = true
        text.isRichText = false
        text.drawsBackground = false
        text.isVerticallyResizable = true
        text.isHorizontallyResizable = false
        text.autoresizingMask = [.width]
        text.minSize = .zero
        text.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        text.textContainer?.widthTracksTextView = true
        text.textContainer?.lineBreakMode = .byCharWrapping
        text.textContainer?.containerSize = NSSize(width: 300, height: CGFloat.greatestFiniteMagnitude)
        text.textContainerInset = NSSize(width: 8, height: 8)
        scroll.documentView = text
        return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let text = scroll.documentView as? PageTextView else { return }
        context.coordinator.update(text, page: page, pageIndex: pageIndex, revision: revealRevision)
    }
    static func dismantleNSView(_ view: NSScrollView, coordinator: Coordinator) {
        (view.documentView as? PageTextView)?.pendingReveal = nil
    }
    final class Coordinator {
        private var pageIndex: Int?
        private var revision: UUID?
        private var previousText: String?
        private var previousHighlight: NSRange?
        func update(_ text: PageTextView, page: LeafValueDocument.StringPage, pageIndex: Int, revision: UUID?) {
            let changedPage = self.pageIndex != pageIndex
            let reveal = changedPage || self.revision != revision
            if previousText?.utf8.elementsEqual(page.text.utf8) != true || previousHighlight != page.highlight {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byCharWrapping
                let display = NSMutableAttributedString(string: page.text, attributes: [
                    .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
                    .foregroundColor: NSColor.textColor,
                    .paragraphStyle: paragraph
                ])
                if let range = page.highlight {
                    display.addAttributes([.backgroundColor: NSColor.selectedTextBackgroundColor,
                                           .foregroundColor: NSColor.selectedTextColor], range: range)
                }
                text.textStorage?.setAttributedString(display)
            }
            if reveal, let range = page.highlight {
                text.pendingReveal = range
            } else if changedPage {
                text.pendingReveal = NSRange(location: 0, length: 0)
            } else if page.highlight == nil {
                text.pendingReveal = nil
            }
            self.pageIndex = pageIndex
            self.revision = revision
            previousText = page.text
            previousHighlight = page.highlight
            text.needsLayout = true
        }
    }
    final class PageTextView: NSTextView {
        var pendingReveal: NSRange?
        override func layout() {
            super.layout()
            guard bounds.width > 0, let range = pendingReveal, let container = textContainer else { return }
            pendingReveal = nil
            layoutManager?.ensureLayout(for: container)
            // Reveal the beginning even when the match spans more than the viewport.
            scrollRangeToVisible(NSRange(location: range.location, length: min(1, range.length)))
        }
    }
}
