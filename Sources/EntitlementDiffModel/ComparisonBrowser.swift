import Foundation
import EntitlementDiffCore

public enum BrowserFilter: String, CaseIterable, Sendable {
    case allChanges, added, removed, changed, unchanged
    public var label: String {
        switch self {
        case .allChanges: "All Changes"
        case .added: "Added"
        case .removed: "Removed"
        case .changed: "Changed"
        case .unchanged: "Unchanged"
        }
    }
    public func includes(_ kind: ChangeKind) -> Bool {
        self == .allChanges ? kind != .unchanged : rawValue == kind.rawValue
    }
}

public struct BrowserSort: SortComparator, Sendable {
    public enum Column: Sendable { case key, change }
    public var column: Column
    public var order: SortOrder
    public init(column: Column = .key, order: SortOrder = .forward) {
        self.column = column
        self.order = order
    }
    private func rank(_ kind: ChangeKind) -> Int {
        switch kind { case .added: 0; case .removed: 1; case .changed: 2; case .unchanged: 3 }
    }
    public func compare(_ lhs: EntitlementChange, _ rhs: EntitlementChange) -> ComparisonResult {
        let result: ComparisonResult
        if column == .change, lhs.kind != rhs.kind {
            result = rank(lhs.kind) < rank(rhs.kind) ? .orderedAscending : .orderedDescending
        } else if lhs.key.utf8.elementsEqual(rhs.key.utf8) {
            result = .orderedSame
        } else {
            result = lhs.key.utf8.lexicographicallyPrecedes(rhs.key.utf8) ? .orderedAscending : .orderedDescending
        }
        if order == .forward { return result }
        return result == .orderedAscending ? .orderedDescending : result == .orderedDescending ? .orderedAscending : .orderedSame
    }
}

/// View preferences only; never changes comparison or report contents.
public struct ComparisonBrowser {
    public var filter: BrowserFilter = .allChanges
    public var query = ""
    public var sortOrder = [BrowserSort()]
    public var selection: String?
    public init() {}
    public var isDefault: Bool { filter == .allChanges && query.isEmpty && sortOrder == [BrowserSort()] }
    public func count(_ filter: BrowserFilter, in rows: [EntitlementChange]) -> Int {
        rows.filter { filter.includes($0.kind) }.count
    }
    public func visibleRows(in rows: [EntitlementChange]) -> [EntitlementChange] {
        rows.filter { filter.includes($0.kind) && (query.isEmpty || $0.key.localizedCaseInsensitiveContains(query)) }
            .sorted { lhs, rhs in
                for comparator in sortOrder {
                    let result = comparator.compare(lhs, rhs)
                    if result != .orderedSame { return result == .orderedAscending }
                }
                return lhs.key.utf8.lexicographicallyPrecedes(rhs.key.utf8)
            }
    }
    public mutating func reconcileSelection(in visibleRows: [EntitlementChange]) {
        if let selection, !visibleRows.contains(where: { $0.id == selection }) { self.selection = nil }
    }
    public mutating func reset() {
        filter = .allChanges
        query = ""
        sortOrder = [BrowserSort()]
    }
}
