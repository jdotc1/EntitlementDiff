import Foundation
#if os(macOS)
import Observation
#endif
import EntitlementDiffCore

// Observation drives the macOS UI; portable tests exercise the same state logic.
#if os(macOS)
@Observable
#endif
@MainActor
public final class ComparisonModel {
    public private(set) var previous: InputState = .empty
    public private(set) var current: InputState = .empty
    public private(set) var architecture: Architecture
    public private(set) var report: ComparisonReport?
    public private(set) var rows: [EntitlementChange] = []
    public private(set) var reportError: String?

    private let reader: any SnapshotReading
    // A constant, private reference is naturally excluded from Observation.
    // Keeping request internals here avoids conditional property attributes
    // that conflict with @Observable's syntax-level macro expansion.
    private let requests = InspectionRequests()

    public init(reader: any SnapshotReading, architecture: Architecture = .hostDefault) {
        self.reader = reader
        self.architecture = architecture
    }

    /// In-memory only; never included in a report or persisted as history.
    public var selectedSourceURLs: [URL] { Array(requests.sourceURLs.values) }

    public var isLoading: Bool { previous.isLoading || current.isLoading }
    public var hasInputs: Bool { !previous.isEmpty || !current.isEmpty }
    public var canSwap: Bool { previous.snapshot != nil && current.snapshot != nil && !isLoading }

    /// Replacing an input invalidates its old result before the new read begins.
    /// Returned tasks support deterministic tests; UI callers may ignore them.
    @discardableResult
    public func load(_ url: URL, side: ComparisonSide) -> Task<Void, Never> {
        invalidate(side)
        requests.sourceURLs[side] = url
        let generation = UUID()
        requests.generations[side] = generation
        let requestedArchitecture = architecture
        let sourceName = url.lastPathComponent
        set(.loading(sourceName: sourceName), side: side)
        updateReport()
        let reader = reader
        let task = Task { [weak self] in
            do {
                try Task.checkCancellation()
                let snapshot = try await reader.read(at: url, architecture: requestedArchitecture)
                try Task.checkCancellation()
                guard let self, self.requests.generations[side] == generation else { return }
                guard snapshot.architecture == requestedArchitecture else { throw ReportError.architectureMismatch }
                self.set(.ready(snapshot), side: side)
                self.requests.tasks[side] = nil
                self.updateReport()
            } catch is CancellationError {
                guard let self, self.requests.generations[side] == generation else { return }
                self.requests.sourceURLs[side] = nil
                self.set(.empty, side: side)
                self.requests.tasks[side] = nil
                self.updateReport()
            } catch {
                guard let self, self.requests.generations[side] == generation else { return }
                self.set(.failed(sourceName: sourceName, message: error.localizedDescription), side: side)
                self.requests.tasks[side] = nil
                self.updateReport()
            }
        }
        requests.tasks[side] = task
        return task
    }

    public func clear(_ side: ComparisonSide) {
        invalidate(side)
        requests.sourceURLs[side] = nil
        set(.empty, side: side)
        updateReport()
    }

    public func clear() {
        for side in ComparisonSide.allCases { invalidate(side) }
        requests.sourceURLs.removeAll()
        previous = .empty
        current = .empty
        updateReport()
    }

    public func setArchitecture(_ architecture: Architecture) {
        guard self.architecture != architecture else { return }
        clear()
        self.architecture = architecture
    }

    @discardableResult
    public func swap() -> Bool {
        guard canSwap else { return false }
        let old = previous
        previous = current
        current = old
        let oldURL = requests.sourceURLs[.previous]
        requests.sourceURLs[.previous] = requests.sourceURLs[.current]
        requests.sourceURLs[.current] = oldURL
        updateReport()
        return true
    }

    public func loadExample(structured: Bool = false) {
        clear()
        let pair = structured ? ExampleSnapshots.structuredPair(architecture: architecture) : ExampleSnapshots.pair(architecture: architecture)
        previous = .ready(pair.previous)
        current = .ready(pair.current)
        updateReport()
    }

    private func invalidate(_ side: ComparisonSide) {
        requests.tasks.removeValue(forKey: side)?.cancel()
        requests.generations[side] = UUID()
    }

    private func set(_ state: InputState, side: ComparisonSide) {
        switch side {
        case .previous: previous = state
        case .current: current = state
        }
    }

    private func updateReport() {
        report = nil
        rows = []
        reportError = nil
        guard let old = previous.snapshot, let new = current.snapshot else { return }
        do {
            report = try ComparisonReport(previous: old, current: new)
            rows = EntitlementComparison(previous: old.entitlements, current: new.entitlements).rows
        } catch {
            reportError = error.localizedDescription
        }
    }
}
