import Foundation
import Observation
import EntitlementDiffModel

/// KMP cursor retains partial matches across bounded portions, including overlapping matches.
struct HexByteCursor: Sendable {
    enum Step: Equatable { case match(Int), more, end }
    static let byteLimit = 32_768
    let source: Data
    private(set) var pattern: [UInt8]
    enum Direction: Sendable { case forward, backward }
    private(set) var direction: Direction = .forward
    private var anchor: Int?
    private var failure: [Int]
    private var offset = 0
    private var matched = 0
    init(source: Data, query: String) throws {
        let raw = Array(query.utf8.prefix(385))
        guard !raw.isEmpty, raw.count <= 383 else { throw Invalid.query }
        var bytes: [UInt8] = [], high: UInt8?
        for c in raw {
            if c == 32 { guard high == nil else { throw Invalid.query }; continue }
            let n: UInt8
            switch c {
            case 48...57: n = c - 48
            case 65...70: n = c - 55
            case 97...102: n = c - 87
            default: throw Invalid.query
            }
            if let h = high { bytes.append(h * 16 + n); high = nil }
            else { high = n }
        }
        guard high == nil, !bytes.isEmpty, bytes.count <= 128 else { throw Invalid.query }
        pattern = bytes; self.source = source
        failure = Self.prefixTable(bytes)
    }
    private static func prefixTable(_ bytes: [UInt8]) -> [Int] {
        var table = Array(repeating: 0, count: bytes.count), prefix = 0
        for i in bytes.indices.dropFirst() {
            while prefix > 0 && bytes[i] != bytes[prefix] { prefix = table[prefix - 1] }
            if bytes[i] == bytes[prefix] { prefix += 1 }
            table[i] = prefix
        }
        return table
    }
    enum Invalid: Error { case query, noMatch }
    /// Excludes the selected start; reversing at its end retains overlapping matches.
    func searching(_ requested: Direction) throws -> Self {
        guard requested != direction else { return self }
        guard let anchor else { throw Invalid.noMatch }
        var next = self
        next.direction = requested; next.pattern.reverse()
        next.failure = Self.prefixTable(next.pattern); next.matched = 0
        next.offset = requested == .forward ? anchor + 1 : anchor + pattern.count - 1
        return next
    }
    mutating func step(limit: Int = Self.byteLimit) throws -> Step {
        try Task.checkCancellation()
        if direction == .backward { return try backwardStep(limit: limit) }
        let budget = min(Self.byteLimit, max(1, limit))
        var consumed = 0
        while offset < source.count && consumed < budget {
            if consumed % 256 == 0 { try Task.checkCancellation() }
            let byte = source[source.index(source.startIndex, offsetBy: offset)]
            while matched > 0 && byte != pattern[matched] { matched = failure[matched - 1] }
            if byte == pattern[matched] { matched += 1 }
            offset += 1; consumed += 1
            if matched == pattern.count {
                let start = offset - matched
                matched = failure[matched - 1]
                anchor = start
                return .match(start)
            }
        }
        try Task.checkCancellation()
        return offset == source.count ? .end : .more
    }
    private mutating func backwardStep(limit: Int) throws -> Step {
        let budget = min(Self.byteLimit, max(1, limit))
        var consumed = 0
        while offset > 0 && consumed < budget {
            if consumed % 256 == 0 { try Task.checkCancellation() }
            offset -= 1
            let byte = source[source.index(source.startIndex, offsetBy: offset)]
            while matched > 0 && byte != pattern[matched] { matched = failure[matched - 1] }
            if byte == pattern[matched] { matched += 1 }
            consumed += 1
            if matched == pattern.count {
                anchor = offset; matched = failure[matched - 1]
                return .match(offset)
            }
        }
        try Task.checkCancellation()
        return offset == 0 ? .end : .more
    }
}

@MainActor @Observable
final class FocusedHexSearch {
    enum Phase { case ready, running, paused, matched, end, invalid, failed }
    typealias Runner = @Sendable (HexByteCursor) async throws -> (HexByteCursor, HexByteCursor.Step)
    private(set) var direction: HexByteCursor.Direction = .forward
    private(set) var query = ""
    private(set) var phase: Phase = .ready
    private(set) var matchOffset: Int?
    private(set) var revision = UUID()
    private(set) var context: String?
    private var matchDetails: String?
    static let copyByteLimit = 1024
    private let source: Data
    @ObservationIgnored private let runner: Runner
    @ObservationIgnored private var cursor: HexByteCursor?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var work: Task<Void, Never>?
    var canAdvance: Bool { phase == .paused || phase == .matched }
    var canReveal: Bool { phase != .running && matchOffset != nil }
    func copyText(side: ComparisonSide) -> String? {
        guard canReveal, let matchDetails else { return nil }
        let text = "\(side.label) hex match details\n" + matchDetails
        return text.utf8.count <= Self.copyByteLimit ? text : nil
    }
    /// Publish only a new reveal identity; retain the cursor, direction and captured context.
    @discardableResult func reveal() -> Bool {
        guard canReveal else { return false }
        revision = UUID()
        return true
    }
    func canSearch(_ requested: HexByteCursor.Direction) -> Bool {
        guard phase != .running, let cursor else { return false }
        return requested == cursor.direction ? canAdvance : matchOffset != nil
    }
    var message: String {
        switch phase {
        case .ready: "Hex pairs · 1–128 bytes · optional spaces."
        case .running: direction == .backward ? "Searching backward through this portion…" : "Searching this portion…"
        case .paused: direction == .backward ? "No previous match yet. Continue Backward to examine more." : "No next match yet. Continue Search to examine more."
        case .matched: "Match at byte \((matchOffset ?? 0) + 1) (1-based). Brackets mark matched bytes; context preview is bounded."
        case .end: direction == .backward ? "Reached the beginning. No earlier match; search does not wrap." : "Reached the end. No further match; search does not wrap."
        case .invalid: "Enter 1–128 hex byte pairs, optionally separated by spaces."
        case .failed: "Search could not complete. Use Find Hex to restart."
        }
    }
    init(source: Data, runner: Runner? = nil) {
        self.source = source
        self.runner = runner ?? { cursor in
            let task = Task.detached(priority: .userInitiated) {
                var next = cursor
                let result = try next.step()
                return (next, result)
            }
            return try await withTaskCancellationHandler { try await task.value } onCancel: { task.cancel() }
        }
    }
    deinit { work?.cancel() }
    func setQuery(_ text: String) {
        let bounded = String(decoding: text.utf8.prefix(384), as: UTF8.self)
        guard query != bounded else { return }
        query = bounded; cancel()
    }
    func clear() {
        query = ""; cancel()
    }
    func cancel() {
        generation = UUID(); work?.cancel(); work = nil; cursor = nil
        matchOffset = nil; context = nil; matchDetails = nil; phase = .ready; direction = .forward
    }
    @discardableResult func find() -> Task<Void, Never>? {
        cancel()
        do { cursor = try HexByteCursor(source: source, query: query) }
        catch { phase = .invalid; return nil }
        return advance()
    }
    @discardableResult func advance(direction requested: HexByteCursor.Direction? = nil) -> Task<Void, Never>? {
        guard phase != .running else { return nil }
        if let requested, let current = cursor, requested != current.direction {
            do { cursor = try current.searching(requested) }
            catch { return nil }
            generation = UUID(); work?.cancel(); work = nil
            direction = requested; phase = .matched
        }
        guard phase == .ready || canAdvance, let cursor else { return nil }
        let request = generation, runner = runner
        phase = .running
        let task = Task {
            do {
                let (next, result) = try await runner(cursor)
                guard !Task.isCancelled, request == generation else { return }
                self.cursor = next
                switch result {
                case .more: phase = .paused
                case .end: phase = .end
                case .match(let offset):
                    matchOffset = offset; revision = UUID(); phase = .matched
                    let end = offset + next.pattern.count
                    let lower = max(0, offset - 8), upper = min(source.count, end + 8)
                    func hex(_ range: Range<Int>) -> String {
                        range.map { String(format: "%02X", source[source.startIndex + $0]) }.joined(separator: " ")
                    }
                    matchDetails = "Byte range: \(offset + 1)–\(end) (1-based, inclusive)\n" +
                        "Match length: \(next.pattern.count) bytes\nMatched bytes: " + hex(offset..<end) +
                        "\nContext before (up to 8 bytes): " + hex(lower..<offset) +
                        "\nContext after (up to 8 bytes): " + hex(end..<upper) + "\n"
                    let previewEnd = min(end, offset + 16)
                    context = "Bytes \(offset + 1)–\(end): " + hex(lower..<offset) + " [" + hex(offset..<previewEnd) +
                        (previewEnd < end ? " …" : "") + "] " + hex(end..<upper)
                }
            } catch {
                guard !Task.isCancelled, request == generation else { return }
                phase = .failed
            }
        }
        work = task; return task
    }
}
