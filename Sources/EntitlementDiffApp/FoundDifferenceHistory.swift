/// Session-only positions; never stores source values or comparison cursors.
struct FoundDifferenceHistory<Position: Sendable>: Sendable {
    static var limit: Int { 64 }
    struct Entry: Sendable {
        let ordinal: Int
        let position: Position
    }
    private(set) var entries: [Entry] = []
    private(set) var index = 0
    var canPrevious: Bool { index > 0 }
    var canNext: Bool { index + 1 < entries.count }
    var isAtFrontier: Bool { !canNext }
    var notice: String? {
        guard let first = entries.first, first.ordinal > 1 else { return nil }
        return "Found history starts at difference \(first.ordinal). Find First Difference to restart."
    }
    mutating func append(_ position: Position) -> Entry {
        let entry = Entry(ordinal: (entries.last?.ordinal ?? 0) + 1, position: position)
        if entries.count == Self.limit { entries.removeFirst() }
        entries.append(entry); index = entries.count - 1
        return entry
    }
    mutating func previous() -> Entry? {
        guard canPrevious else { return nil }
        index -= 1; return entries[index]
    }
    mutating func next() -> Entry? {
        guard canNext else { return nil }
        index += 1; return entries[index]
    }
}
