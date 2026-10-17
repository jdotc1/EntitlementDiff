import Foundation
import Observation
import EntitlementDiffCore

@MainActor @Observable
final class FocusedStringDifference {
    enum Phase { case ready, running, paused, different, equal, failed }
    typealias Runner = @Sendable (StringFirstDifference) async throws -> (StringFirstDifference, StringFirstDifference.Step)
    private(set) var phase: Phase = .ready
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
        case .paused: "No difference yet. Continue Comparison to examine more."
        case .equal: "No difference. Both original strings are equal."
        case .failed: "Comparison could not complete. Use Find First Difference to restart."
        case .different:
            if let position {
                "First difference at scalar position \(position.scalarOffset + 1) (starts at byte \(position.byteOffset + 1))." +
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
        cursor = nil; position = nil; phase = .ready
    }
    @discardableResult
    func find() -> Task<Void, Never>? {
        cancel(); cursor = StringFirstDifference(previous: previous, current: current)
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
                case .equal: phase = .equal
                case .difference(let found): position = found; revision = UUID(); phase = .different
                }
            } catch {
                guard !Task.isCancelled, generation == request else { return }
                phase = .failed
            }
        }
        work = task; return task
    }
}
