import Foundation
import Observation
import EntitlementDiffCore

@MainActor @Observable
final class FocusedDataDifference {
    enum Phase { case ready, running, paused, different, equal, failed }
    typealias Runner = @Sendable (DataFirstDifference) async throws -> (DataFirstDifference, DataFirstDifference.Step)
    private(set) var phase: Phase = .ready
    private(set) var position: DataFirstDifference.Position?
    private(set) var previousContext: DataDifferenceContext?
    private(set) var currentContext: DataDifferenceContext?
    private(set) var revision = UUID()
    private let previous: Data
    private let current: Data
    @ObservationIgnored private let runner: Runner
    @ObservationIgnored private var cursor: DataFirstDifference?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var work: Task<Void, Never>?

    var message: String {
        switch phase {
        case .ready: "Compare original bytes in explicit portions; values remain base64."
        case .running: "Comparing this portion…"
        case .paused: "No difference yet. Continue Comparison to examine more."
        case .equal: "No difference. Both original data values are equal."
        case .failed: "Comparison could not complete. Use Find First Difference to restart."
        case .different:
            if let position {
                "First difference at byte \(position.byteOffset + 1)." +
                (position.previousByte == nil ? " Previous ends here; Current continues." :
                 position.currentByte == nil ? " Current ends here; Previous continues." : "")
            } else { "Difference found." }
        }
    }
    init(previous: Data, current: Data, runner: Runner? = nil) {
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
        cursor = nil; position = nil; previousContext = nil; currentContext = nil; phase = .ready
    }
    @discardableResult
    func find() -> Task<Void, Never>? {
        cancel(); cursor = DataFirstDifference(previous: previous, current: current)
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
                case .difference(let found):
                    // At most 33 original bytes per side; published under the same generation guard.
                    previousContext = DataDifferenceContext(data: previous, byteOffset: found.byteOffset)
                    currentContext = DataDifferenceContext(data: current, byteOffset: found.byteOffset)
                    position = found; revision = UUID(); phase = .different
                }
            } catch {
                guard !Task.isCancelled, generation == request else { return }
                phase = .failed
            }
        }
        work = task; return task
    }
}
