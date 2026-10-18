import SwiftUI
import EntitlementDiffCore
import EntitlementDiffModel

struct ChangeDetailView: View {
    let change: EntitlementChange?
    let comparisonRevision: UUID
    let copy: (EntitlementChange) -> Void
    let copyKey: () -> Void
    let inspect: (EntitlementChange, InspectorRow) -> Void
    let copyBranch: (ComparisonSide, InspectorRow, String, UUID) -> Void
    let openTreeHit: (TreeTextSearchSession, EntitlementTreeSearch.Hit) -> Void
    let busy: Bool
    @State private var searchingTree = false
    @State private var treeSession: TreeTextSearchSession?
    @State private var browsingBranch = false
    @State private var session: InspectorProjectionSession?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let change {
                HStack {
                    Text(EntitlementValue.string(change.key).preview(maxCharacters: 512))
                        .font(.system(.headline, design: .monospaced)).lineLimit(2).textSelection(.enabled)
                    Spacer()
                    Button("Copy Exact Key", action: copyKey).disabled(busy)
                    Button("Copy Selected JSON") { copy(change) }
                    Button("Browse Branches") { browsingBranch = true }.disabled(busy || browsingBranch)
                    Button("Collapse") { browsingBranch = false; session?.collapse() }.disabled(busy)
                }
                Button(searchingTree ? "Show Inspector" : "Find Tree Text…") { searchingTree.toggle() }.disabled(busy)
                if searchingTree, let treeSession {
                    TreeTextSearchView(session: treeSession, open: { openTreeHit(treeSession, $0) }, busy: busy)
                } else if browsingBranch {
                    InspectorBranchView(change: change, inspect: inspect,
                                        copyBranch: { side, row in copyBranch(side, row, change.id, comparisonRevision) },
                                        close: { browsingBranch = false }, busy: busy)
                } else if let session,
                          session.comparisonRevision == comparisonRevision,
                          session.selectionID == change.id {
                    inspector(change, session: session)
                } else { ProgressView().controlSize(.small) }
            } else {
                Text("Select an entitlement to inspect its typed values.")
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(12)
        .onAppear { if session == nil { replaceSession() } }
        .onChange(of: comparisonRevision) { _, _ in replaceSession() }
        .onChange(of: change?.id) { _, _ in replaceSession() }
    }

    private func replaceSession() {
        treeSession?.cancel(); searchingTree = false
        treeSession = change.map { TreeTextSearchSession(change: $0, revision: comparisonRevision) }
        browsingBranch = false
        session = change.map { InspectorProjectionSession(change: $0, comparisonRevision: comparisonRevision) }
    }

    private func inspector(_ change: EntitlementChange, session: InspectorProjectionSession) -> some View {
        let projection = session.projection

        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                TextField("Search nested paths", text: Binding(get: { session.query }, set: { self.session?.setQuery($0) })).textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                Toggle("Changes only", isOn: Binding(get: { session.changesOnly }, set: { self.session?.setChangesOnly($0) })).toggleStyle(.checkbox)
                Spacer()
                Button("Previous Page") { self.session?.previousPage() }
                    .disabled(projection.pageOffset == 0)
                Button("Reveal More") { self.session?.nextPage() }
                    .disabled(!projection.hasNextPage)
            }

            HStack {
                Text("Path · Change").frame(maxWidth: .infinity, alignment: .leading)
                Text("Previous").frame(maxWidth: .infinity, alignment: .leading)
                Text("Current").frame(maxWidth: .infinity, alignment: .leading)
            }.font(.caption.weight(.semibold))
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(projection.rows) { row in
                        HStack(alignment: .top, spacing: 12) {
                            HStack(alignment: .top, spacing: 4) {
                                if row.expandable && session.query.isEmpty {
                                    Button(session.expanded.contains(row.id) ? "▾" : "▸") {
                                        self.session?.toggleExpansion(row.id)
                                    }.buttonStyle(.borderless)
                                }
                                Text("\(projection.pageOffset == 0 ? row.label : EntitlementValue.string(row.displayPath).preview(maxCharacters: 512)) · \(row.kind.label)").textSelection(.enabled)
                                    .help(EntitlementValue.string(row.displayPath).preview(maxCharacters: 512))
                                if row.hasLeafValue {
                                    Button("View Value…") { inspect(change, row) }.disabled(busy)
                                }
                            }
                            .padding(.leading, CGFloat(row.depth) * 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(InspectorRow.summary(row.previous)).textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(InspectorRow.summary(row.current)).textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.font(.system(.caption, design: .monospaced))
                    }
                }
            }
            if projection.rows.isEmpty {
                Text(projection.searchIncomplete ? "No matching paths in the inspected portion." : "No matching paths.")
                    .foregroundStyle(.secondary)
            }
            Text("\(projection.rows.count) shown · \(projection.matchingRowCount) paths in inspected portion · page \(projection.pageOffset / 50 + 1)")
                .font(.caption).foregroundStyle(.secondary)
            Text(projection.searchIncomplete
                 ? "Inspection limit reached (2,000 nodes or 12 levels). Some paths remain unsearched. Browse Branches to reach later or deeper values. Copy Selected JSON contains complete values."
                 : "50 rows per page · up to 2,000 inspected nodes · 12 levels · 256 scalars per preview. Search opens collapsed paths; arrays compare by index. Copy contains complete values.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
