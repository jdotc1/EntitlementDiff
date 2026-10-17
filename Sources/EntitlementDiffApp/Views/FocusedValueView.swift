import SwiftUI
import EntitlementDiffCore
import EntitlementDiffModel

/// Immutable values captured by an explicit row action, not resolved from truncated labels.
struct FocusedValueSelection: Identifiable {
    let id = UUID()
    let entitlementKey: String
    let pathPreview: String
    let previous: EntitlementValue?
    let current: EntitlementValue?

    func value(for side: ComparisonSide) -> EntitlementValue? {
        side == .previous ? previous : current
    }
}

struct FocusedValueView: View {
    let selection: FocusedValueSelection
    @Bindable var actions: AppActions
    @State private var difference: FocusedStringDifference?
    @State private var dataDifference: FocusedDataDifference?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focused Value").font(.title2.weight(.semibold))
            Text(EntitlementValue.string(selection.entitlementKey).preview(maxCharacters: 512))
                .font(.system(.headline, design: .monospaced)).textSelection(.enabled)
            Text("Path (preview): \(EntitlementValue.string(selection.pathPreview).preview(maxCharacters: 512))")
                .foregroundStyle(.secondary).lineLimit(3).textSelection(.enabled)
            if let difference {
                HStack {
                    Button(difference.phase == .paused ? "Continue Comparison" : "Find First Difference") {
                        if difference.phase == .paused { difference.advance() } else { difference.find() }
                    }
                    .disabled(difference.phase == .running)
                    if difference.position != nil {
                        Button("Previous Found Difference") { difference.previousFound() }.disabled(!difference.canPrevious)
                        Button("Find Next Difference") { difference.next() }.disabled(!difference.canNext)
                        Button("Reveal Difference") { difference.reveal() }
                    }
                    if difference.phase == .running { ProgressView().controlSize(.small) }
                }
                if let notice = difference.historyNotice { Text(notice).font(.caption).foregroundStyle(.secondary) }
                Text(difference.message).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let dataDifference {
                HStack {
                    Button(dataDifference.phase == .paused ? "Continue Comparison" : "Find First Difference") {
                        if dataDifference.phase == .paused { dataDifference.advance() } else { dataDifference.find() }
                    }
                    .disabled(dataDifference.phase == .running)
                    if dataDifference.position != nil {
                        Button("Previous Found Difference") { dataDifference.previousFound() }.disabled(!dataDifference.canPrevious)
                        Button("Find Next Difference") { dataDifference.next() }.disabled(!dataDifference.canNext)
                        Button("Reveal Difference") { dataDifference.reveal() }
                    }
                    if dataDifference.phase == .running { ProgressView().controlSize(.small) }
                }
                if let notice = dataDifference.historyNotice { Text(notice).font(.caption).foregroundStyle(.secondary) }
                Text(dataDifference.message).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .top, spacing: 16) {
                ForEach(ComparisonSide.allCases, id: \.self) { side in
                    LeafValuePane(side: side, value: selection.value(for: side),
                                  copying: actions.isWritingReport, copy: { actions.copyLeaf(side) },
                                  differencePosition: difference?.position, differenceRevision: difference?.revision,
                                  dataDifferencePosition: dataDifference?.position, dataDifferenceRevision: dataDifference?.revision,
                                  dataContext: side == .previous ? dataDifference?.previousContext : dataDifference?.currentContext)
                }
            }
            Text("Values are captured when opened. Strings escape control characters; data is base64. Copy Leaf JSON includes the complete typed value, regardless of the page.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                if actions.isWritingReport { ProgressView().controlSize(.small) }
                Text(DisplayText.escaped(actions.statusMessage)).font(.caption).lineLimit(3)
                Spacer()
                Button("Done") { actions.focusedValue = nil }
                    .keyboardShortcut(.cancelAction)
                    .disabled(actions.isWritingReport)
            }
        }
        .padding(20)
        .frame(width: 880, height: 560)
        .interactiveDismissDisabled(actions.isWritingReport)
        .task(id: selection.id) {
            difference?.cancel(); dataDifference?.cancel()
            if case .string(let previous) = selection.previous, case .string(let current) = selection.current {
                difference = FocusedStringDifference(previous: previous, current: current)
            } else { difference = nil }
            if case .data(let previous) = selection.previous, case .data(let current) = selection.current {
                dataDifference = FocusedDataDifference(previous: previous, current: current)
            } else { dataDifference = nil }
        }
        .onDisappear { difference?.cancel(); dataDifference?.cancel() }
    }
}

private struct LeafValuePane: View {
    let side: ComparisonSide
    let value: EntitlementValue?
    let copying: Bool
    let copy: () -> Void
    let differencePosition: StringFirstDifference.Position?
    let differenceRevision: UUID?
    let dataDifferencePosition: DataFirstDifference.Position?
    let dataDifferenceRevision: UUID?
    let dataContext: DataDifferenceContext?
    @State private var showingDifference = false
    @State private var document: LeafValueDocument?
    @State private var navigation = LeafPageNavigation()
    @State private var preparationError: String?
    @State private var search: FocusedStringSearch?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(side.label).font(.headline)
            Text(value?.typeName ?? "Absent").foregroundStyle(.secondary)
            if let position = differencePosition {
                let detail = side == .previous ? position.previousDetail : position.currentDetail
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "Difference: " + detail.scalarLabel).font(.system(.caption, design: .monospaced))
                    if let bytes = detail.utf8Bytes {
                        Text("UTF-8: \(bytes)").font(.system(.caption, design: .monospaced))
                    }
                }
                .font(.caption).textSelection(.enabled)
            }
            if let position = dataDifferencePosition {
                let byte = side == .previous ? position.previousByte : position.currentByte
                Text(byte == nil ? "Difference: End of data" :
                     "Difference byte: " + (side == .previous ? position.previousLabel : position.currentLabel))
                    .font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            }
            if let dataContext { DataHexContextView(context: dataContext) }
            if let document {
                if let page = stringPage(document) {
                    HighlightedStringPageView(page: page, pageIndex: navigation.index,
                                              revealRevision: showingDifference ? differenceRevision : search?.matchRevision)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                    if page.continuesBefore || page.continuesAfter {
                        Text(page.continuesBefore && page.continuesAfter ? "Match continues from the previous page and onto the next." :
                             page.continuesBefore ? "Match continues from the previous page." : "Match continues onto the next page.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    ScrollView {
                        Text(verbatim: document.text(onPage: navigation.index))
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                    .id(DataPageIdentity(page: navigation.index, revision: dataDifferenceRevision))
                }
                if showingDifference, let position = differencePosition,
                   byteCount(position) == 0, navigation.index == document.pageCount - 1 {
                    Text("End of string at difference (closing quote marked).")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text("Page \(navigation.index + 1) of \(document.pageCount)").font(.caption).monospacedDigit()
                HStack {
                    Button("First") { navigation.select(0, pageCount: document.pageCount) }.disabled(navigation.index == 0)
                    Button("Previous") { navigation.select(navigation.index - 1, pageCount: document.pageCount) }.disabled(navigation.index == 0)
                    Button("Next") { navigation.select(navigation.index + 1, pageCount: document.pageCount) }.disabled(navigation.index + 1 == document.pageCount)
                    Button("Last") { navigation.select(document.pageCount - 1, pageCount: document.pageCount) }.disabled(navigation.index + 1 == document.pageCount)
                }
                HStack {
                    TextField("Page number", text: $navigation.input)
                        .textFieldStyle(.roundedBorder).frame(width: 90)
                        .onSubmit { navigation.go(pageCount: document.pageCount) }
                    Button("Go") { navigation.go(pageCount: document.pageCount) }
                    Text("1–\(document.pageCount)").font(.caption).foregroundStyle(.secondary)
                }
                if navigation.isInvalid {
                    Text("Enter a whole page number from 1 through \(document.pageCount).")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else if InspectorLeaf(value) != nil {
                if let preparationError {
                    Text(DisplayText.escaped(preparationError))
                } else {
                    ProgressView("Preparing value…")
                }
                Spacer()
            } else {
                Text(value == nil ? "No value on this side." : "This side is a container. Choose one of its nested values in the inspector.")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            if let search {
                HStack {
                    ExactKeyField(input: Binding(get: { search.input }, set: { search.setQuery($0) }),
                                  placeholder: "Find literal text", submit: { search.find() }, edited: {})
                        .frame(height: 24)
                    Button("Find") { search.find() }
                }
                HStack {
                    Button(search.phase == .paused && search.direction == .backward ? "Continue Backward" : "Find Previous") {
                        search.advance(direction: .backward)
                    }
                    .disabled(!search.canSearch(.backward))
                    Button(search.phase == .paused && search.direction == .forward ? "Continue Search" : "Find Next") {
                        search.advance(direction: .forward)
                    }
                    .disabled(!search.canSearch(.forward))
                    if search.phase == .running { ProgressView().controlSize(.small) }
                }
                Text(search.message).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("Copy \(side.label) Leaf JSON", action: copy)
                .disabled(InspectorLeaf(value) == nil || copying)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: differenceRevision) { _, _ in revealDifference() }
        .onChange(of: dataDifferenceRevision) { _, _ in revealDataDifference() }
        .onChange(of: differencePosition) { _, position in
            if position == nil { showingDifference = false }
        }
        .onChange(of: search?.phase) { _, phase in
            if phase == .running { showingDifference = false }
        }
        .onChange(of: search?.matchRevision) { _, _ in
            if let page = search?.match?.pageIndex, let document {
                showingDifference = false
                navigation.select(page, pageCount: document.pageCount)
            }
        }
        .onDisappear { search?.cancel() }
        .task {
            guard let leaf = InspectorLeaf(value) else { return }
            let work = Task.detached(priority: .userInitiated) { try LeafValueDocument(leaf: leaf) }
            do {
                let prepared = try await withTaskCancellationHandler {
                    try await work.value
                } onCancel: {
                    work.cancel()
                }
                try Task.checkCancellation()
                document = prepared
                revealDifference(); revealDataDifference()
                if case .string(let text) = leaf.value { search = FocusedStringSearch(source: text) }
            } catch is CancellationError {
                // The sheet was dismissed; never publish a late preparation result.
            } catch {
                preparationError = error.localizedDescription
            }
        }
    }

    private func byteCount(_ position: StringFirstDifference.Position) -> Int {
        side == .previous ? position.previousByteCount : position.currentByteCount
    }
    private func stringPage(_ document: LeafValueDocument) -> LeafValueDocument.StringPage? {
        if showingDifference, let position = differencePosition {
            return document.stringDifferencePage(onPage: navigation.index, byteOffset: side == .previous ? position.previousByteOffset : position.currentByteOffset,
                                                 scalarByteCount: byteCount(position))
        }
        return document.stringPage(onPage: navigation.index, matching: search?.matchByteRange)
    }
    private func revealDifference() {
        guard let document, let position = differencePosition else { return }
        showingDifference = true
        navigation.select(min(position.pageIndex, document.pageCount - 1), pageCount: document.pageCount)
    }

    private func revealDataDifference() {
        guard let document, let position = dataDifferencePosition else { return }
        navigation.select(min(position.pageIndex, document.pageCount - 1), pageCount: document.pageCount)
    }

}


private struct DataPageIdentity: Hashable {
    let page: Int
    let revision: UUID?
}

private struct DataHexContextView: View {
    let context: DataDifferenceContext

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Hex context").font(.caption.weight(.semibold))
            Text(verbatim: context.rangeLabel).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 1) {
                if !context.beforeHex.isEmpty { Text(verbatim: context.beforeHex) }
                Text(verbatim: context.markedHex).fontWeight(.semibold)
                if !context.afterHex.isEmpty { Text(verbatim: context.afterHex) }
            }
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
