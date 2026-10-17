import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers
import EntitlementDiffCore
import EntitlementDiffModel

/// UI action boundary: file/save panels, validated URL drops and explicit clipboard actions.
@Observable
@MainActor
final class AppActions {
    @ObservationIgnored private let model: ComparisonModel
    private(set) var isPresentingPanel = false
    private(set) var isWritingReport = false
    private(set) var isCopyingBranch = false
    var errorMessage: String?
    private(set) var statusMessage = ""
    var focusedValue: FocusedValueSelection?
    var savedReport: SavedReport?
    private(set) var isReadingSavedReport = false
    var isFindingEntitlement = false
    private(set) var findRevealID: String?
    private(set) var findRevealRevision = UUID()
    var isBusy: Bool { isFindingEntitlement || isPresentingPanel || isWritingReport || isReadingSavedReport || focusedValue != nil || savedReport != nil }

    @ObservationIgnored private let readSavedReport: @Sendable (URL) async throws -> SavedReport
    @ObservationIgnored private let writeExactKey: (String) -> Bool
    var canCopyExactKey: Bool { !isBusy && model.browser.selectedRow != nil }

    init(model: ComparisonModel, writeExactKey: ((String) -> Bool)? = nil,
         readSavedReport: (@Sendable (URL) async throws -> SavedReport)? = nil) {
        self.model = model
        self.readSavedReport = readSavedReport ?? { url in
            try await Task.detached(priority: .userInitiated) {
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                return try SavedReport.read(at: url)
            }.value
        }
        self.writeExactKey = writeExactKey ?? { key in
            let clipboard = NSPasteboard.general
            clipboard.clearContents()
            return clipboard.setData(Data(key.utf8), forType: .string)
        }
    }

    func copyExactKey() {
        guard canCopyExactKey, let key = model.browser.selectedRow?.key else { return }
        statusMessage = ""
        if writeExactKey(key) {
            statusMessage = "Complete exact key copied as raw UTF-8 text."
        } else {
            errorMessage = "The system clipboard did not accept the entitlement key."
        }
    }

    func canMoveToChange(_ direction: ComparisonBrowser.ChangeDirection) -> Bool {
        !isBusy && model.report != nil && model.browser.changeTarget(direction) != nil
    }

    func moveToChange(_ direction: ComparisonBrowser.ChangeDirection) {
        guard canMoveToChange(direction), let id = model.browser.moveToChange(direction) else { return }
        // Share the existing table reveal mechanism used by exact Find.
        findRevealID = id
        findRevealRevision = UUID()
        statusMessage = ""
    }

    func beginFindEntitlement() {
        guard !isBusy, model.report != nil else { return }
        isFindingEntitlement = true
    }

    func findEntitlement(_ key: String, revealHidden: Bool) -> ComparisonBrowser.ExactFindResult {
        guard isFindingEntitlement, model.report != nil else { return .missing }
        let result = model.browser.findExactKey(key, revealHidden: revealHidden)
        if case .found(let id) = result {
            findRevealID = id
            findRevealRevision = UUID()
            isFindingEntitlement = false
            statusMessage = "Exact entitlement selected. Reports still include the complete comparison."
        }
        return result
    }

    func openSavedReport() {
        guard !isBusy else { return }
        isPresentingPanel = true
        let panel = NSOpenPanel()
        panel.title = "Open Saved Report"
        panel.message = "Choose an EntitlementDiff schema-1 JSON report. No app paths are opened from the report."
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        let result = panel.runModal()
        isPresentingPanel = false
        guard result == .OK, let url = panel.url else { return }
        _ = receiveSavedReportURLs([url])
    }

    /// Finder/Launch Services and the picker share one read/review boundary.
    /// Busy requests are rejected, never queued to replace the session later.
    @discardableResult
    func receiveSavedReportURLs(_ urls: [URL]) -> Task<Void, Never>? {
        guard !isBusy, errorMessage == nil else {
            statusMessage = "Finish the current action, then open the saved report again."
            return nil
        }
        guard urls.count == 1, let url = urls.first, url.isFileURL,
              url.host == nil || url.host == "" || url.host == "localhost" else {
            errorMessage = "Open exactly one local EntitlementDiff JSON report at a time."
            return nil
        }
        isReadingSavedReport = true
        statusMessage = "Reading saved report…"
        return Task {
            defer { isReadingSavedReport = false }
            do {
                let report = try await readSavedReport(url)
                savedReport = report
                statusMessage = "Review saved snapshots before replacing this session."
            } catch {
                statusMessage = ""
                errorMessage = "Could not open saved report. " + error.localizedDescription
            }
        }
    }

    func adoptSavedBaseline(_ snapshot: EntitlementSnapshot) {
        guard savedReport != nil else { return }
        model.useSavedBaseline(snapshot)
        savedReport = nil
        statusMessage = "Saved baseline adopted. Choose a Current app for a fresh inspection."
    }

    func openSavedComparison() {
        guard let savedReport else { return }
        model.openSavedComparison(savedReport)
        self.savedReport = nil
        statusMessage = "Saved comparison opened. Both snapshots are unverified saved metadata."
    }

    func choose(_ side: ComparisonSide) {
        guard !isBusy else { return }
        isPresentingPanel = true
        defer { isPresentingPanel = false }
        let panel = NSOpenPanel()
        panel.title = "Choose \(side.label) Application"
        panel.message = "Read the main executable's \(model.architecture.rawValue) entitlement declarations. The application will not be launched."
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = false
        panel.resolvesAliases = true
        panel.prompt = "Inspect"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        statusMessage = ""
        model.load(url, side: side)
    }

    @discardableResult
    func drop(_ urls: [URL], side: ComparisonSide) -> Bool {
        guard !isBusy else { return false }
        do {
            let url = try ApplicationDrop.applicationURL(from: urls)
            statusMessage = ""
            model.load(url, side: side)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func reveal(_ side: ComparisonSide) {
        guard !isBusy, let url = model.selectedSourceURL(for: side) else { return }
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func reload(_ side: ComparisonSide? = nil) {
        guard !isBusy else { return }
        if let side {
            let state = side == .previous ? model.previous : model.current
            guard model.canReload(side), !state.isLoading else { return }
            statusMessage = ""
            model.reload(side)
        } else {
            guard model.canReloadBoth, !model.isLoading else { return }
            statusMessage = ""
            model.reloadBoth()
        }
    }

    func setArchitecture(_ architecture: Architecture) {
        guard !isBusy else { return }
        statusMessage = ""
        model.setArchitecture(architecture)
    }

    func clear(_ side: ComparisonSide? = nil) {
        guard !isBusy else { return }
        statusMessage = ""
        if let side { model.clear(side) } else { model.clear() }
    }

    func swap() {
        guard !isBusy else { return }
        statusMessage = ""
        model.swap()
    }

    func loadStructuredExample() {
        guard !isBusy else { return }
        statusMessage = ""
        model.loadExample(structured: true)
    }

    func loadExample() {
        guard !isBusy else { return }
        statusMessage = ""
        model.loadExample()
    }

    func inspectValue(_ change: EntitlementChange, row: InspectorRow) {
        guard !isBusy, row.hasLeafValue else { return }
        statusMessage = ""
        focusedValue = .init(entitlementKey: change.key, pathPreview: row.displayPath,
                             previous: row.previous, current: row.current)
    }

    /// Capture the chosen side before suspension. Paging never changes the payload.
    @discardableResult
    func copyLeaf(_ side: ComparisonSide, to clipboard: NSPasteboard = .general) -> Task<Void, Never>? {
        guard !isPresentingPanel, !isWritingReport,
              let leaf = InspectorLeaf(focusedValue?.value(for: side)) else { return nil }
        isWritingReport = true
        statusMessage = "Preparing complete \(side.label.lowercased()) leaf JSON…"
        return Task {
            defer { isWritingReport = false }
            do {
                let data = try await Task.detached(priority: .userInitiated) { try leaf.jsonData() }.value
                clipboard.clearContents()
                guard clipboard.setString(String(decoding: data, as: UTF8.self), forType: .string) else {
                    statusMessage = "Could not copy leaf JSON: the system clipboard did not accept it."
                    return
                }
                statusMessage = "Complete \(side.label.lowercased()) leaf JSON copied. It includes the value and its type."
            } catch {
                statusMessage = "Could not copy leaf JSON: \(error.localizedDescription)"
            }
        }
    }

    /// Validate view ownership and capture the complete chosen container before suspension.
    @discardableResult
    func copyBranch(_ side: ComparisonSide, row: InspectorRow, entitlementID: String,
                    comparisonRevision: UUID, to clipboard: NSPasteboard = .general) -> Task<Void, Never>? {
        guard !isBusy, comparisonRevision == model.reportRevision,
              model.browser.selectedRow?.id == entitlementID,
              let branch = BranchJSONValue(side == .previous ? row.previous : row.current) else { return nil }
        isWritingReport = true
        isCopyingBranch = true
        statusMessage = "Preparing complete \(side.label.lowercased()) branch JSON…"
        return Task {
            defer { isWritingReport = false; isCopyingBranch = false }
            do {
                let data = try await Task.detached(priority: .userInitiated) { try branch.jsonData() }.value
                guard comparisonRevision == model.reportRevision,
                      model.browser.selectedRow?.id == entitlementID else {
                    statusMessage = "Comparison or selection changed; branch JSON was not copied."
                    return
                }
                clipboard.clearContents()
                guard clipboard.setString(String(decoding: data, as: UTF8.self), forType: .string) else {
                    statusMessage = "Could not copy branch JSON: the system clipboard did not accept it."
                    return
                }
                statusMessage = "Complete \(side.label.lowercased()) branch JSON copied. It includes all children and their types."
            } catch {
                statusMessage = "Could not copy branch JSON: \(error.localizedDescription)"
            }
        }
    }

    func copySelected(_ change: EntitlementChange) {
        guard !isBusy else { return }
        isWritingReport = true
        Task {
            defer { isWritingReport = false }
            do {
                let data = try await Task.detached(priority: .userInitiated) { try change.selectedJSON() }.value
                let clipboard = NSPasteboard.general
                clipboard.clearContents()
                guard clipboard.setString(String(decoding: data, as: UTF8.self), forType: .string) else {
                    errorMessage = "Could not copy selected entitlement."
                    return
                }
                statusMessage = "Complete selected entitlement JSON copied. It includes entitlement values."
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func copyReport() {
        guard !isBusy, let report = model.report else { return }
        isWritingReport = true
        statusMessage = "Preparing complete report…"
        Task {
            let text = await Task.detached(priority: .userInitiated) { report.text() }.value
            let clipboard = NSPasteboard.general
            clipboard.clearContents()
            if clipboard.setString(text, forType: .string) {
                statusMessage = "Complete report copied. It includes entitlement values."
            } else {
                statusMessage = ""
                errorMessage = "The system clipboard did not accept the report."
            }
            isWritingReport = false
        }
    }

    func exportJSON() {
        guard !isBusy, let report = model.report else { return }
        isPresentingPanel = true
        defer { isPresentingPanel = false }
        let panel = NSSavePanel()
        panel.title = "Export Complete Comparison"
        panel.message = "Exports both complete snapshots and every change, regardless of the table filter. Includes names, identifiers and entitlement values; review before sharing."
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "EntitlementDiff-report.json"
        panel.canCreateDirectories = true
        panel.treatsFilePackagesAsDirectories = false
        guard panel.runModal() == .OK, let destination = panel.url else { return }
        let inputs = model.selectedSourceURLs
        isWritingReport = true
        statusMessage = "Writing complete report…"
        Task {
            do {
                try await Task.detached(priority: .userInitiated) {
                    let access = destination.startAccessingSecurityScopedResource()
                    defer { if access { destination.stopAccessingSecurityScopedResource() } }
                    try ReportDestination.validate(destination, excluding: inputs)
                    let data = try report.jsonData()
                    try ReportDestination.validate(destination, excluding: inputs)
                    try data.write(to: destination, options: .atomic)
                }.value
                statusMessage = "Complete JSON report exported."
            } catch {
                statusMessage = ""
                errorMessage = error.localizedDescription
            }
            isWritingReport = false
        }
    }
}
