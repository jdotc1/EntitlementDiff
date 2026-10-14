import SwiftUI
import EntitlementDiffCore
import EntitlementDiffModel

struct ChangeTable: View {
    let rows: [EntitlementChange]
    @Binding var selection: String?

    @Binding var sortOrder: [BrowserSort]

    var body: some View {
        Table(rows, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Change", sortUsing: BrowserSort(column: .change)) { row in
                Label(row.kind.label, systemImage: symbol(row.kind))
                    .font(.caption)
                    .foregroundStyle(row.kind == .unchanged ? .secondary : .primary)
            }.width(min: 100, ideal: 112, max: 130)
            TableColumn("Entitlement", sortUsing: BrowserSort(column: .key)) { row in
                Text(EntitlementValue.string(row.key).preview(maxCharacters: 512))
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1).truncationMode(.middle)
                    .help(EntitlementValue.string(row.key).preview(maxCharacters: 512))
            }.width(min: 220, ideal: 390)
            TableColumn("Previous") { row in
                Text(row.previous?.preview() ?? "<absent>")
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
            }.width(min: 130, ideal: 210)
            TableColumn("Current") { row in
                Text(row.current?.preview() ?? "<absent>")
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
            }.width(min: 130, ideal: 210)
        }
        .accessibilityLabel("Entitlement comparison. Select a row to inspect its values.")
    }

    private func symbol(_ kind: ChangeKind) -> String {
        switch kind {
        case .added: "plus.circle"
        case .removed: "minus.circle"
        case .changed: "arrow.left.arrow.right.circle"
        case .unchanged: "equal.circle"
        }
    }
}
