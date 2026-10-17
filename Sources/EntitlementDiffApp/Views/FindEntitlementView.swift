import SwiftUI
import EntitlementDiffModel

struct FindEntitlementView: View {
    let find: (String, Bool) -> ComparisonBrowser.ExactFindResult
    let cancel: () -> Void
    @State private var input = ExactKeyInput()
    @State private var result: ComparisonBrowser.ExactFindResult?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Find Entitlement").font(.title2)
            Text("Enter the complete key. Matching uses exact UTF-8 bytes, including case and whitespace.")
                .foregroundStyle(.secondary)
            ExactKeyField(input: $input, placeholder: "Exact entitlement key", initiallyFocused: true,
                          submit: { result = find(input.value, false) }, cancel: cancel) {
                result = nil
            }.frame(height: 24)
            if result == .hidden {
                Text("The key exists but is hidden by the current search or category. Show in All Keys clears search and keeps your sorting.")
                Button("Show in All Keys") { result = find(input.value, true) }
            } else if result == .missing {
                Text("No exact key found. Your filters and selection are unchanged.")
            }
            HStack {
                Button("Cancel", action: cancel).keyboardShortcut(.cancelAction)
                Spacer()
                Button("Find") { result = find(input.value, false) }.keyboardShortcut(.defaultAction)
            }
        }.padding(24).frame(width: 480)
    }
}
