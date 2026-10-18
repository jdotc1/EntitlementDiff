import EntitlementDiffModel
import SwiftUI
import EntitlementDiffCore

struct TreeTextSearchView: View {
    @Bindable var session: TreeTextSearchSession
    let open: (EntitlementTreeSearch.Hit) -> Void
    let busy: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ExactKeyField(input: Binding(get: { session.input }, set: { session.setQuery($0) }),
                              placeholder: "Find text in string values", submit: { session.search() }, edited: {})
                    .frame(height: 24)
                Button("Search Tree") { session.search() }.disabled(session.running || busy)
                Button("Continue Tree Search") { session.advance() }
                    .disabled(session.running || busy || session.cursor == nil || session.cursor?.complete == true || session.cursor?.limited == true)
            }
            Text(session.message).font(.caption).foregroundStyle(.secondary)
            Text("Literal UTF-8 · first match per string leaf · 64 traversal operations and one 32 KiB string portion per action · up to 200 results. Data and other value types are excluded.")
                .font(.caption).foregroundStyle(.secondary)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(session.cursor?.hits ?? []) { hit in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading) {
                                Text(verbatim: hit.side.label + " · " + hit.pathPreview).lineLimit(3)
                                Text("Match at UTF-8 byte \(hit.match.byteOffset + 1), scalar \(hit.match.scalarOffset + 1) · \(hit.queryByteCount) query bytes")
                                    .font(.caption)
                            }
                            Spacer()
                            Button("Open Match…") { open(hit) }.disabled(busy || session.running)
                        }
                    }
                }
            }
        }
        .frame(minHeight: 280)
        .onDisappear { session.cancel() }
    }
}
