import Foundation
import Observation
import EntitlementDiffCore

@MainActor @Observable
final class FocusedStringDifference {
    enum Phase { case ready, running, paused, different, equal, finished, failed }
    typealias Runner = @Sendable (StringFirstDifference) async throws -> (StringFirstDifference, StringFirstDifference.Step)
    private(set) var phase: Phase = .ready
    private(set) var differenceCount = 0
    private(set) var position: StringFirstDifference.Position?
    private(set) var revision = UUID()
    private let previous: String
    private let current: String
    @ObservationIgnored private let runner: Runner
    @ObservationIgnored private var cursor: StringFirstDifference?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var work: Task<Void, Never>?

    var message: String {
        switch phase {
        case .ready: "Compare original strings in explicit portions; no text alignment is inferred."
        case .running: "Comparing this portion…"
        case .paused: position == nil ? "No difference yet. Continue Comparison to examine more." : "No further difference yet. Continue Comparison to examine more."
        case .equal: "No difference. Both original strings are equal."
        case .finished: "No further differences. The last difference remains available to reveal."
        case .failed: "Comparison could not complete. Use Find First Difference to restart."
        case .different:
            if let position {
                (differenceCount == 1 ? "First difference" : "Difference \(differenceCount)") +
                " at scalar position \(position.scalarOffset + 1) (Previous byte \(position.previousByteOffset + 1), Current byte \(position.currentByteOffset + 1))." +
                (position.previousByteCount == 0 ? " Previous ends here; Current continues." :
                 position.currentByteCount == 0 ? " Current ends here; Previous continues." : "")
            } else { "Difference found." }
        }
    }
    init(previous: String, current: String, runner: Runner? = nil) {
        self.previous = previous; self.current = current
        self.runner = runner ?? { cursor in
            let task = Task.detached(priority: .userInitiated) {
                var next = cursor; let result = try next.step(); return (next, result)
            }
            return try await withTaskCancellationHandler { try await task.value } onCancel: { task.cancel() }
        }
    }
    deinit { work?.cancel() }
    func cancel() {
        generation = UUID(); work?.cancel(); work = nil
        cursor = nil; differenceCount = 0; position = nil; phase = .ready
    }
    @discardableResult
    func find() -> Task<Void, Never>? {
        cancel(); cursor = StringFirstDifference(previous: previous, current: current)
        return advance()
    }
    @discardableResult
    func next() -> Task<Void, Never>? {
        guard phase == .different, var cursor, cursor.movePastDifference() else { return nil }
        generation = UUID(); work?.cancel(); work = nil
        self.cursor = cursor; phase = .ready
        return advance()
    }
    func reveal() { if position != nil { revision = UUID() } }
    @discardableResult
    func advance() -> Task<Void, Never>? {
        guard phase == .ready || phase == .paused, let cursor else { return nil }
        let request = generation, runner = runner
        phase = .running
        let task = Task {
            do {
                let (next, step) = try await runner(cursor)
                guard !Task.isCancelled, generation == request else { return }
                self.cursor = next
                switch step {
                case .more: phase = .paused
                case .equal: phase = position == nil ? .equal : .finished
                case .difference(let found): differenceCount += 1; position = found; revision = UUID(); phase = .different
                }
            } catch {
                guard !Task.isCancelled, generation == request else { return }
                phase = .failed
            }
        }
        work = task; return task
    }
}
