import Foundation
import Observation
import EntitlementDiffCore

@MainActor @Observable
final class FocusedStringSearch {
    enum Phase { case ready, running, paused, matched, end, invalid, failed }
    typealias Runner = @Sendable (StringValueSearch) async throws -> (StringValueSearch, StringValueSearch.Step)
    private(set) var input = ExactKeyInput()
    private(set) var phase: Phase = .ready
    private(set) var match: StringValueSearch.Match?
    private(set) var matchRevision = UUID()
    private let source: String
    @ObservationIgnored private let runner: Runner
    @ObservationIgnored private var cursor: StringValueSearch?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var work: Task<Void, Never>?
    var canAdvance: Bool { phase == .paused || phase == .matched }
    var matchByteRange: Range<Int>? {
        guard let match else { return nil }
        return match.byteOffset..<(match.byteOffset + input.value.utf8.count)
    }
    var message: String {
        switch phase {
        case .ready: "Literal UTF-8 · 1–1,024 query bytes."
        case .running: "Searching this portion…"
        case .paused: "No next match yet. Continue Search to examine more."
        case .matched:
            if let match { "Match begins at byte \(match.byteOffset + 1) · page \(match.pageIndex + 1)." }
            else { "Match found." }
        case .end: "Reached the end. No further match; search does not wrap."
        case .invalid: "Enter literal text from 1 through 1,024 UTF-8 bytes."
        case .failed: "Search could not complete. Use Find to restart."
        }
    }
    init(source: String, runner: Runner? = nil) {
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
    func setQuery(_ input: ExactKeyInput) {
        guard self.input != input else { return }
        self.input = input
        cancel()
    }
    func cancel() {
        generation = UUID(); work?.cancel(); work = nil
        cursor = nil; match = nil; phase = .ready
    }
    @discardableResult
    func find() -> Task<Void, Never>? {
        cancel()
        do { cursor = try StringValueSearch(source: source, query: input.value) }
        catch { phase = .invalid; return nil }
        return advance()
    }
    @discardableResult
    func advance() -> Task<Void, Never>? {
        guard phase != .running, let cursor else { return nil }
        guard phase == .ready || canAdvance else { return nil }
        let request = generation, runner = runner
        phase = .running
        let task = Task {
            do {
                let (next, step) = try await runner(cursor)
                guard !Task.isCancelled, request == generation else { return }
                self.cursor = next
                switch step {
                case .match(let found):
                    match = found; matchRevision = UUID(); phase = .matched
                case .more: phase = .paused
                case .end: phase = .end
                }
            } catch {
                guard !Task.isCancelled, request == generation else { return }
                phase = .failed
            }
        }
        work = task
        return task
    }
}
