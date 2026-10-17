import SwiftUI
import EntitlementDiffCore
import EntitlementDiffModel

struct ContentView: View {
    @Bindable var model: ComparisonModel
    @Bindable var actions: AppActions

    private var browser: ComparisonBrowser { model.browser }
    private var visibleRows: [EntitlementChange] { browser.visibleRows }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if model.report != nil {
                comparison
            } else {
                waitingState
            }
            Divider()
            footer
        }
        .frame(minWidth: 880, minHeight: 650)
        .sheet(item: $actions.focusedValue) { selection in
            FocusedValueView(selection: selection, actions: actions).id(selection.id)
        }
        .toolbar {
            ToolbarItemGroup {
                Button { actions.reload() } label: { Label("Reload Both", systemImage: "arrow.clockwise") }
                    .disabled(!model.canReloadBoth || model.isLoading || actions.isBusy)
                Button { actions.swap() } label: { Label("Swap", systemImage: "arrow.left.arrow.right") }
                    .disabled(!model.canSwap || actions.isBusy)
                Button { actions.copyReport() } label: { Label("Copy Report", systemImage: "doc.on.doc") }
                    .disabled(model.report == nil || actions.isBusy)
                Button { actions.exportJSON() } label: { Label("Export JSON…", systemImage: "square.and.arrow.up") }
                    .disabled(model.report == nil || actions.isBusy)
            }
        }
        .alert("EntitlementDiff", isPresented: Binding(
            get: { actions.errorMessage != nil },
            set: { if !$0 { actions.errorMessage = nil } }
        )) {
            Button("OK") { actions.errorMessage = nil }
        } message: {
            Text(DisplayText.escaped(actions.errorMessage ?? ""))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Compare embedded entitlements").font(.title2.weight(.semibold))
                    Text("Read-only declarations, not effective permissions or a security verdict.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Picker("Architecture", selection: Binding(
                    get: { model.architecture }, set: { actions.setArchitecture($0) }
                )) {
                    ForEach(Architecture.allCases, id: \.self) { architecture in
                        Text(architecture.rawValue).tag(architecture)
                    }
                }
                .frame(width: 190).disabled(actions.isBusy)
                .help("Both inputs must contain this architecture. Changing it clears the selections. No fallback slice is used.")
            }
            HStack(alignment: .top, spacing: 14) {
                SourcePane(side: .previous, state: model.previous, disabled: actions.isBusy,
                           sourceURL: model.selectedSourceURL(for: .previous), reveal: { actions.reveal(.previous) },
                           canReload: model.canReload(.previous), reload: { actions.reload(.previous) },
                           choose: { actions.choose(.previous) }, clear: { actions.clear(.previous) },
                           drop: { actions.drop($0, side: .previous) })
                SourcePane(side: .current, state: model.current, disabled: actions.isBusy,
                           sourceURL: model.selectedSourceURL(for: .current), reveal: { actions.reveal(.current) },
                           canReload: model.canReload(.current), reload: { actions.reload(.current) },
                           choose: { actions.choose(.current) }, clear: { actions.clear(.current) },
                           drop: { actions.drop($0, side: .current) })
            }
            Text("Main executable · requested architecture only. Other slices and nested code are excluded. Signature validity, Gatekeeper and notarization are not checked.")
                .font(.caption).foregroundStyle(.secondary)
            if let report = model.report {
                if report.previous.origin == .syntheticExample || report.current.origin == .syntheticExample {
                    Label("Synthetic example — these values were not read from installed applications.", systemImage: "info.circle")
                        .font(.caption)
                }
                if !report.previous.signingIdentifier.utf8.elementsEqual(report.current.signingIdentifier.utf8) {
                    Label("Signing identifiers differ. Confirm that these are the intended builds.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                }
            }
        }.padding(16)
    }

    private var comparison: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                TextField("Filter entitlement keys", text: $model.browser.query)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Filter entitlement keys")
                    .frame(maxWidth: 280)
                Picker("Show", selection: $model.browser.filter) {
                    ForEach(BrowserFilter.allCases, id: \.self) { filter in
                        Text("\(filter.label) (\(browser.count(filter)))").tag(filter)
                    }
                }.frame(width: 210)
                Button("Nested Example") { actions.loadStructuredExample() }.disabled(actions.isBusy)
                Button("Reset View") { model.browser.reset() }
                    .disabled(browser.isDefault)
                Spacer()
                Text("\(visibleRows.count) shown · \(model.report?.changes.count ?? 0) changes · \(model.report?.unchangedCount ?? 0) unchanged")
                    .font(.caption).monospacedDigit().foregroundStyle(.secondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            VSplitView {
                ChangeTable(rows: visibleRows, selection: $model.browser.selection, sortOrder: $model.browser.sortOrder)
                    .overlay {
                        if visibleRows.isEmpty {
                            VStack(spacing: 5) {
                                Text(model.report?.changes.isEmpty == true && browser.filter == .allChanges && browser.query.isEmpty
                                     ? "No entitlement-value changes in this scope."
                                     : "No keys match the current filters.")
                                Text("Exports always include the complete comparison.").font(.caption)
                            }.foregroundStyle(.secondary).padding()
                        }
                    }
                    .frame(minHeight: 180, idealHeight: 260)
                ChangeDetailView(change: browser.selectedRow, copy: actions.copySelected,
                                 inspect: actions.inspectValue, busy: actions.isBusy)
                    .id(model.reportRevision).id(browser.selectedRow?.id)
                    .frame(minHeight: 155, idealHeight: 205)
            }
        }
    }

    private var waitingState: some View {
        VStack(spacing: 12) {
            Image(systemName: model.isLoading ? "doc.text.magnifyingglass" : "square.split.2x1")
                .font(.system(size: 32)).foregroundStyle(.secondary)
            Text(model.isLoading ? "Reading selected application metadata…" : "Choose two app builds to begin")
                .font(.title3.weight(.medium))
            Text(model.reportError ?? "Previous → Current. Unsigned or unreadable inputs do not become empty comparisons.")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            if !model.isLoading {
                Button("Load Synthetic Example") { actions.loadExample() }.disabled(actions.isBusy)
            }
            if model.isLoading {
                Button("Cancel and Clear") { actions.clear() }.disabled(actions.isBusy)
            }
        }
        .padding(30).frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if actions.isWritingReport { ProgressView().controlSize(.small) }
            Text(actions.statusMessage.isEmpty
                 ? "No history is saved. Reports include names, identifiers and entitlement values; review before sharing."
                 : actions.statusMessage)
                .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            Spacer()
            Button("Clear Both") { actions.clear() }
                .disabled(!model.hasInputs || actions.isBusy)
        }.padding(.horizontal, 16).padding(.vertical, 10)
    }
}
