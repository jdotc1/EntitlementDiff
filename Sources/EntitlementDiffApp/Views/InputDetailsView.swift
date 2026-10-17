import SwiftUI
import EntitlementDiffCore
import EntitlementDiffModel

struct InputDetailsView: View {
    let state: InputState
    let sourceURL: URL?
    let disabled: Bool
    let reveal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Input Details").font(.headline)
            field("Selected location", sourceURL?.path, limit: 4_096)
            if let snapshot = state.snapshot {
                if snapshot.isSavedBaseline {
                    Text("Saved report — unverified metadata. No selected app location or build metadata.")
                        .foregroundStyle(.secondary)
                } else if snapshot.origin == .syntheticExample {
                    Text("Synthetic example — no selected file or build metadata.").foregroundStyle(.secondary)
                } else {
                    field("Bundle identifier", snapshot.identity?.bundleIdentifier)
                    field("Version", snapshot.identity?.version)
                    field("Build number", snapshot.identity?.build)
                }
                field("Signing identifier", snapshot.signingIdentifier, limit: 4_096)
                Text("Requested architecture: \(snapshot.architecture.rawValue)")
            } else {
                Text(state.isLoading ? "Build metadata is being read…" : "Build metadata unavailable because inspection failed.")
                    .foregroundStyle(.secondary)
            }
            Button("Reveal in Finder", action: reveal).disabled(sourceURL == nil || disabled || state.isLoading)
            Text("Bundle metadata is unverified display information. Location is session-only; reports omit it. Optional fields are limited to 256 UTF-8 bytes. Long locations and identifiers are previewed.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(16).frame(width: 420)
    }

    private func field(_ title: String, _ value: String?, limit: Int = 256) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption.weight(.semibold))
            Text(value.map { EntitlementValue.string($0).preview(maxCharacters: limit) } ?? "Unavailable")
                .font(.system(.caption, design: .monospaced)).textSelection(.enabled)
        }
    }
}
