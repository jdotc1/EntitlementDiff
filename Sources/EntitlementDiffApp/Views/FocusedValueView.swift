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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focused Value").font(.title2.weight(.semibold))
            Text(EntitlementValue.string(selection.entitlementKey).preview(maxCharacters: 512))
                .font(.system(.headline, design: .monospaced)).textSelection(.enabled)
            Text("Path (preview): \(EntitlementValue.string(selection.pathPreview).preview(maxCharacters: 512))")
                .foregroundStyle(.secondary).lineLimit(3).textSelection(.enabled)
            HStack(alignment: .top, spacing: 16) {
                ForEach(ComparisonSide.allCases, id: \.self) { side in
                    LeafValuePane(side: side, value: selection.value(for: side),
                                  copying: actions.isWritingReport, copy: { actions.copyLeaf(side) })
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
    }
}

private struct LeafValuePane: View {
    let side: ComparisonSide
    let value: EntitlementValue?
    let copying: Bool
    let copy: () -> Void
    @State private var document: LeafValueDocument?
    @State private var navigation = LeafPageNavigation()
    @State private var preparationError: String?
    @State private var search: FocusedStringSearch?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(side.label).font(.headline)
            Text(value?.typeName ?? "Absent").foregroundStyle(.secondary)
            if let document {
                ScrollView {
                    Text(verbatim: document.text(onPage: navigation.index))
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
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
                    Button(search.phase == .paused ? "Continue Search" : "Find Next") { search.advance() }
                        .disabled(!search.canAdvance)
                    if search.phase == .running { ProgressView().controlSize(.small) }
                }
                Text(search.message).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("Copy \(side.label) Leaf JSON", action: copy)
                .disabled(InspectorLeaf(value) == nil || copying)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: search?.matchRevision) { _, _ in
            if let page = search?.match?.pageIndex, let document {
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
                if case .string(let text) = leaf.value { search = FocusedStringSearch(source: text) }
            } catch is CancellationError {
                // The sheet was dismissed; never publish a late preparation result.
            } catch {
                preparationError = error.localizedDescription
            }
        }
    }
}
