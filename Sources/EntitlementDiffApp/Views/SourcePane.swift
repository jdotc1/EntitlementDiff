import SwiftUI
import EntitlementDiffCore
import EntitlementDiffModel

struct SourcePane: View {
    let side: ComparisonSide
    let state: InputState
    let disabled: Bool
    let sourceURL: URL?
    let reveal: () -> Void
    let canReload: Bool
    let reload: () -> Void
    let choose: () -> Void
    let clear: () -> Void
    let drop: ([URL]) -> Bool
    @State private var showsDetails = false
    @State private var isDropTargeted = false

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(side.label).font(.headline)
                    Spacer()
                    if canReload {
                        Button(state.errorMessage == nil ? "Reload" : "Retry", action: reload)
                            .disabled(disabled || state.isLoading)
                            .help("Read this selected app again using the selected architecture.")
                    }
                    if !state.isEmpty {
                        Button("Clear", action: clear).buttonStyle(.borderless)
                            .disabled(disabled)
                            .accessibilityLabel("Clear \(side.label.lowercased()) input")
                    }
                    Button(state.isEmpty ? "Choose App…" : "Replace…", action: choose)
                        .disabled(disabled)
                        .accessibilityLabel("Choose \(side.label.lowercased()) application")
                }
                Text(state.sourceName.map(DisplayText.escaped) ?? "No application selected")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(state.isEmpty ? .secondary : .primary)
                    .lineLimit(2)
                    .textSelection(.enabled)
                stateDescription
                if !state.isEmpty {
                    Button("Input Details…") { showsDetails = true }
                        .buttonStyle(.borderless)
                        .popover(isPresented: $showsDetails) {
                            InputDetailsView(state: state, sourceURL: sourceURL, disabled: disabled, reveal: reveal)
                        }
                }
                Text("Drop one .app here to inspect or replace this input.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 98, alignment: .topLeading)
            .padding(4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isDropTargeted && !disabled ? Color.accentColor : Color.clear, lineWidth: 2)
                .allowsHitTesting(false)
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard !disabled else { return false }
            return drop(urls)
        } isTargeted: { isDropTargeted = $0 }
        .accessibilityElement(children: .contain)
    }

    private func display(_ value: String?) -> String {
        value.map { EntitlementValue.string($0).preview(maxCharacters: 256) } ?? "Unavailable"
    }

    @ViewBuilder private var stateDescription: some View {
        switch state {
        case .empty:
            Text("Select a signed .app build, including ad-hoc signed builds.")
                .font(.caption).foregroundStyle(.secondary)
        case .loading:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Reading metadata…").font(.caption)
            }
        case .failed(_, let message):
            Label {
                Text(DisplayText.escaped(message)).font(.caption).textSelection(.enabled)
            } icon: { Image(systemName: "exclamationmark.triangle") }
            .accessibilityLabel("Inspection failed: \(DisplayText.escaped(message))")
        case .ready(let snapshot):
            VStack(alignment: .leading, spacing: 3) {
                if snapshot.isSavedBaseline {
                    Text("Saved report — unverified metadata; not a fresh inspection.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if snapshot.origin == .extracted && !snapshot.isSavedBaseline {
                    Text("Version \(display(snapshot.identity?.version)) · Build \(display(snapshot.identity?.build))")
                        .font(.caption).lineLimit(2).textSelection(.enabled)
                }
                Text("\(snapshot.entitlements.entries.count) keys · \(snapshot.architecture.rawValue) requested")
                    .font(.caption).monospacedDigit()
                Text(DisplayText.escaped(snapshot.signingIdentifier))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    .help(DisplayText.escaped(snapshot.signingIdentifier))
                if snapshot.presence == .notPresent {
                    Text("No embedded entitlement dictionary returned.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if snapshot.entitlements.entries.isEmpty {
                    Text("Explicitly empty entitlement dictionary.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}
