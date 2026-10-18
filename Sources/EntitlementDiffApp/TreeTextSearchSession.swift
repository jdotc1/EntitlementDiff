import EntitlementDiffModel
import Foundation
import Observation
import EntitlementDiffCore

@MainActor @Observable final class TreeTextSearchSession {
    let selectionID: String
    let comparisonRevision: UUID
    private let previous: EntitlementValue?
    private let current: EntitlementValue?
    private(set) var input = ExactKeyInput()
    private(set) var cursor: EntitlementTreeSearch?
    private(set) var selectedHitID: UUID?
    var selectedIndex: Int? { cursor?.hits.firstIndex { $0.id == selectedHitID } }
    var selectedHit: EntitlementTreeSearch.Hit? {
        guard let index = selectedIndex else { return nil }
        return cursor?.hits[index]
    }
    var canSelectPrevious: Bool { !running && (selectedIndex ?? 0) > 0 }
    var canSelectNext: Bool {
        !running && (selectedIndex.map { $0 + 1 } ?? 0) < (cursor?.hits.count ?? 0)
    }
    var positionLabel: String {
        guard let index = selectedIndex else { return "No result selected." }
        return "Result \(index + 1) of \(cursor?.hits.count ?? 0) found."
    }
    func selectHit(_ id: UUID) {
        guard !running, cursor?.hits.contains(where: { $0.id == id }) == true else { return }
        selectedHitID = id
    }
    func previousResult() {
        guard canSelectPrevious, let index = selectedIndex else { return }
        selectedHitID = cursor?.hits[index - 1].id
    }
    func nextResult() {
        guard canSelectNext else { return }
        selectedHitID = cursor?.hits[selectedIndex.map { $0 + 1 } ?? 0].id
    }
    private(set) var running = false
    private(set) var message = "Search string values. First occurrence per leaf; Previous then Current."
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var task: Task<Void, Never>?
    typealias Runner = @Sendable (EntitlementTreeSearch) async throws -> EntitlementTreeSearch
    @ObservationIgnored private let runner: Runner
    init(change: EntitlementChange, revision: UUID, runner: Runner? = nil) {
        selectionID = change.id; comparisonRevision = revision
        previous = change.previous; current = change.current
        self.runner = runner ?? { cursor in
            let work = Task.detached { var next = cursor; try next.step(); return next }
            return try await withTaskCancellationHandler { try await work.value } onCancel: { work.cancel() }
        }
    }
    func setQuery(_ value: ExactKeyInput) {
        let bounded = ExactKeyInput(value: String(decoding: value.value.utf8.prefix(1025), as: UTF8.self))
        guard input != bounded else { return }
        cancel(); selectedHitID = nil; input = bounded; cursor = nil; message = "Query changed. Use Search Tree."
    }
    var canClear: Bool { running || cursor != nil || selectedHitID != nil || !input.value.isEmpty }
    func clear() {
        cancel()
        input = ExactKeyInput()
        cursor = nil
        selectedHitID = nil
        message = "Search cleared. Enter text and use Search Tree."
    }
    func cancel() { generation = UUID(); task?.cancel(); task = nil; running = false }
    @discardableResult func search() -> Task<Void, Never>? {
        cancel(); selectedHitID = nil
        do { cursor = try EntitlementTreeSearch(previous: previous, current: current, query: input.value) }
        catch { cursor = nil; message = "Enter 1–1,024 UTF-8 query bytes."; return nil }
        return advance()
    }
    @discardableResult func advance() -> Task<Void, Never>? {
        guard !running, let cursor, !cursor.complete, !cursor.limited else { return nil }
        running = true; let request = generation, runner = runner
        let work = Task { [weak self] in
            do {
                let next = try await runner(cursor)
                guard let self, !Task.isCancelled, request == self.generation else { return }
                self.cursor = next; self.running = false
                self.message = next.limited ? "Search incomplete: result limit 200 or path depth limit 128 reached. Narrow the query or browse branches." : next.complete ? "Search complete. \(next.hits.count) matching string leaves." : "Search incomplete. \(next.visited) nodes visited; \(next.hits.count) matching leaves. Continue to search further."
            } catch {
                guard let self, request == self.generation else { return }
                self.running = false; self.message = "Search did not complete. Use Search Tree to restart."
            }
        }
        task = work; return work
    }
}
