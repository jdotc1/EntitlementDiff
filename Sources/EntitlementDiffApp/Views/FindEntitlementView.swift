import SwiftUI
import EntitlementDiffModel

struct FindEntitlementView: View {
    let find: (String, Bool) -> ComparisonBrowser.ExactFindResult
    let cancel: () -> Void
    @State private var key = ""
    @State private var result: ComparisonBrowser.ExactFindResult?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Find Entitlement").font(.title2)
            Text("Enter the complete key. Matching uses exact UTF-8 bytes, including case and whitespace.")
                .foregroundStyle(.secondary)
            TextField("Exact entitlement key", text: $key)
                .textFieldStyle(.roundedBorder).focused($focused)
                .onChange(of: Array(key.utf8)) { _, _ in result = nil }
            if result == .hidden {
                Text("The key exists but is hidden by the current search or category. Show in All Keys clears search and keeps your sorting.")
                Button("Show in All Keys") { result = find(key, true) }
            } else if result == .missing {
                Text("No exact key found. Your filters and selection are unchanged.")
            }
            HStack {
                Button("Cancel", action: cancel).keyboardShortcut(.cancelAction)
                Spacer()
                Button("Find") { result = find(key, false) }.keyboardShortcut(.defaultAction)
            }
        }.padding(24).frame(width: 480)
        .onAppear { focused = true }
    }
}
