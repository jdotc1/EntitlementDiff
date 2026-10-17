import SwiftUI
import EntitlementDiffCore

struct InspectorBranchView: View {
    let change: EntitlementChange
    let inspect: (EntitlementChange, InspectorRow) -> Void
    let close: () -> Void
    let busy: Bool
    @State private var navigation: InspectorBranchNavigator
    @State private var arrayIndex = ""
    @State private var indexError = false

    init(change: EntitlementChange, inspect: @escaping (EntitlementChange, InspectorRow) -> Void,
         close: @escaping () -> Void, busy: Bool) {
        self.change = change; self.inspect = inspect; self.close = close; self.busy = busy
        _navigation = State(initialValue: InspectorBranchNavigator(previous: change.previous, current: change.current))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Button("Back to Search", action: close)
                Button("Up") { navigation.back(); resetIndex() }.disabled(!navigation.canGoBack)
                Text("Branch level \(navigation.depth)").font(.caption)
                Spacer()
                Button("First Children") { navigation.firstPage(); resetIndex() }.disabled(!navigation.hasPrevious)
                Button("Previous Children") { navigation.previousPage(); resetIndex() }.disabled(!navigation.hasPrevious)
                Button("Next Children") { navigation.nextPage(); resetIndex() }.disabled(!navigation.hasNext)
            }
            Text("Path (tail preview): \(navigation.root.displayPath)")
                .font(.caption).lineLimit(2).textSelection(.enabled)
            if let count = navigation.arrayCount {
                HStack {
                    TextField("Array index", text: $arrayIndex).textFieldStyle(.roundedBorder).frame(width: 125)
                    Button("Go to Index") {
                        guard let index = Int(arrayIndex), navigation.goToArrayIndex(index) else { indexError = true; return }
                        indexError = false
                    }
                    Text(indexError ? "Enter an index from 0 through \(max(0, count - 1))." : "\(count) array slots · zero-based indices")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    valueRow(navigation.root, isRoot: true)
                    Divider()
                    ForEach(navigation.rows) { row in valueRow(row, isRoot: false) }
                }
            }
            .id(navigation.root.id + ":" + String(navigation.offset))
            Text(navigation.rows.isEmpty ? "No child values in this branch." : "Children \(navigation.offset + 1)–\(navigation.offset + navigation.rows.count) · \(navigation.hasNext ? "more children remain" : "end of this branch")")
                .font(.caption).foregroundStyle(.secondary)
            Text("50 immediate children per step. Descendants are not searched or compared here; open a branch to continue. Search limits still apply in Back to Search. Copy Selected JSON remains complete.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .disabled(busy)
    }

    private func valueRow(_ row: InspectorRow, isRoot: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            HStack {
                Text(isRoot ? "Branch" : row.label).lineLimit(3).textSelection(.enabled)
                if !isRoot && row.hasContainerValue {
                    Button("Open Branch") { _ = navigation.enter(row.id); resetIndex() }
                }
                if row.hasLeafValue { Button("View Value…") { inspect(change, row) } }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Text("Previous: \(InspectorRow.summary(row.previous))").textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Current: \(InspectorRow.summary(row.current))").textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }.font(.system(.caption, design: .monospaced))
    }

    private func resetIndex() { arrayIndex = ""; indexError = false }
}
