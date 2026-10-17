import SwiftUI
import EntitlementDiffCore

struct ChangeDetailView: View {
    let change: EntitlementChange?
    let copy: (EntitlementChange) -> Void
    let copyKey: () -> Void
    let inspect: (EntitlementChange, InspectorRow) -> Void
    let busy: Bool
    @State private var browsingBranch = false
    @State private var query = ""
    @State private var changesOnly = false
    @State private var page = 0
    @State private var expanded: Set<String> = ["root"]

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
                    Button("Collapse") { browsingBranch = false; expanded = []; query = ""; page = 0 }
                }
                if browsingBranch {
                    InspectorBranchView(change: change, inspect: inspect,
                                        close: { browsingBranch = false }, busy: busy)
                } else { inspector(change) }
            } else {
                Text("Select an entitlement to inspect its typed values.")
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(12)
        .onChange(of: change?.id) { _, _ in expanded = ["root"]; query = ""; changesOnly = false; page = 0 }
    }

    private func inspector(_ change: EntitlementChange) -> some View {
        let projection = ValueInspector(previous: change.previous, current: change.current, expanded: expanded,
                                        maxRows: 50, query: query, changesOnly: changesOnly, offset: page)

        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                TextField("Search nested paths", text: $query).textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                Toggle("Changes only", isOn: $changesOnly).toggleStyle(.checkbox)
                Spacer()
                Button("Previous Page") { page = max(0, projection.pageOffset - 50) }
                    .disabled(projection.pageOffset == 0)
                Button("Reveal More") { page = projection.pageOffset + 50 }
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
                                if row.expandable && query.isEmpty {
                                    Button(expanded.contains(row.id) ? "▾" : "▸") {
                                        if !expanded.insert(row.id).inserted { expanded.remove(row.id) }; page = 0
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
        .onChange(of: query) { _, value in
            let bounded = String(value.unicodeScalars.prefix(256))
            if bounded != value { query = bounded }
            page = 0
        }
        .onChange(of: changesOnly) { _, _ in page = 0 }

    }
}
