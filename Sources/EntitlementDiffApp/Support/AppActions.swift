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
    var errorMessage: String?
    private(set) var statusMessage = ""
    var isBusy: Bool { isPresentingPanel || isWritingReport }

    init(model: ComparisonModel) { self.model = model }

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
