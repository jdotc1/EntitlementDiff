import Foundation
import Observation

/// KMP cursor retains partial matches across bounded portions, including overlapping matches.
struct HexByteCursor: Sendable {
    enum Step: Equatable { case match(Int), more, end }
    static let byteLimit = 32_768
    let source: Data
    let pattern: [UInt8]
    private let failure: [Int]
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
        var table = Array(repeating: 0, count: bytes.count), prefix = 0
        for i in bytes.indices.dropFirst() {
            while prefix > 0 && bytes[i] != bytes[prefix] { prefix = table[prefix - 1] }
            if bytes[i] == bytes[prefix] { prefix += 1 }
            table[i] = prefix
        }
        failure = table
    }
    enum Invalid: Error { case query }
    mutating func step(limit: Int = Self.byteLimit) throws -> Step {
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
                return .match(start)
            }
        }
        try Task.checkCancellation()
        return offset == source.count ? .end : .more
    }
}

@MainActor @Observable
final class FocusedHexSearch {
    enum Phase { case ready, running, paused, matched, end, invalid, failed }
    typealias Runner = @Sendable (HexByteCursor) async throws -> (HexByteCursor, HexByteCursor.Step)
    private(set) var query = ""
    private(set) var phase: Phase = .ready
    private(set) var matchOffset: Int?
    private(set) var revision = UUID()
    private(set) var context: String?
    private let source: Data
    @ObservationIgnored private let runner: Runner
    @ObservationIgnored private var cursor: HexByteCursor?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var work: Task<Void, Never>?
    var canAdvance: Bool { phase == .paused || phase == .matched }
    var message: String {
        switch phase {
        case .ready: "Hex pairs · 1–128 bytes · optional spaces."
        case .running: "Searching this portion…"
        case .paused: "No next match yet. Continue Search to examine more."
        case .matched: "Match at byte \((matchOffset ?? 0) + 1) (1-based). Brackets mark matched bytes; context preview is bounded."
        case .end: "Reached the end. No further match; search does not wrap."
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
    func cancel() {
        generation = UUID(); work?.cancel(); work = nil; cursor = nil
        matchOffset = nil; context = nil; phase = .ready
    }
    @discardableResult func find() -> Task<Void, Never>? {
        cancel()
        do { cursor = try HexByteCursor(source: source, query: query) }
        catch { phase = .invalid; return nil }
        return advance()
    }
    @discardableResult func advance() -> Task<Void, Never>? {
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
