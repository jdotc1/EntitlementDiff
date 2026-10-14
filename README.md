# EntitlementDiff

A lightweight Swift library and native SwiftUI macOS app for comparing embedded
app entitlements between builds.

Choose a previous and current `.app`, select **arm64** or **x86_64**, and inspect
added, removed, and changed declarations. Unknown keys remain visible; the tool
does not assign risk scores or interpret an entitlement as proof of a vulnerability.

**Scope:** the requested architecture of the main executable only. No nested-code
audit, signature verification, Gatekeeper assessment, notarization check, or
claim about effective permissions.

## Build and run

Requires macOS 14+ and a Swift 6 toolchain with macOS command-line developer tools.
No external package dependencies, project generators, credentials, or administrator
access are required for the development build.

```sh
./script/verify.sh
./script/build_and_run.sh
```

The second command builds the executable, stages and ad-hoc signs a real
`dist/EntitlementDiff.app`, and opens it. Do not launch this GUI using a raw
`swift run` executable. 

`./script/build_and_run.sh --build-only` stages without launching;
`--verify` checks that this checkout's process appeared after launch, not that
its UI works. `CONFIGURATION=release ./script/build_and_run.sh --build-only`
produces a release-optimized **development** bundle. It is not a Developer ID
signed, hardened, sandboxed, or notarized distribution release.

Open `Package.swift` in Xcode for editing and debugging. The SwiftPM manifest is
canonical; there is no generated `.xcodeproj` to keep synchronized.

## Workflow

Select the previous build with Command-1 and the current build with Command-2.
You can also drop one local `.app` onto the Previous or Current pane to select or
replace that input. Drops use the same requested architecture and native validation
as the file panel. Multiple items, web URLs and non-app files are rejected.
Native Finder drops into both panes, explicit architecture rejection and invalid-file
recovery passed locally. Focused drop policy/action tests and the app build also passed.
The app reads each selection without launching it. Both must contain the selected
architecture and readable signing metadata; ad-hoc signatures are accepted.
Unsigned, unsupported, and unreadable inputs show errors, not empty comparisons.

Use the table to select a key and inspect its previous/current typed values.
Search filters raw key text; the **Show** picker isolates Added, Removed, Changed or Unchanged entries.
**All Changes** is the default. Category counts describe the full comparison;
the shown count reflects both category and key search. Click the **Change** or
**Entitlement** table header to sort; click again to reverse. Key sorting preserves
UTF-8 byte identity. **Reset View** clears search and restores All Changes and
ascending key order. Selected details survive sorting and filters that keep the
row, and clear when the selected row leaves the view.
The selected-entitlement inspector expands nested dictionaries and positional
arrays with typed Previous/Current values and per-path change labels. Display is
bounded to 50 rows per page, 2,000 inspected nodes, 12 levels and 256 scalars per
preview. Search nested paths through collapsed descendants, enable Changes only,
and use Previous Page / Reveal More to navigate the inspected portion. Scan/depth
limits are explicit; paging does not bypass them. Copy Selected JSON retains the
complete selected entitlement using tagged values; browser filters and expansion
do not reduce it. Nested Example loads a separate synthetic demonstration.

**Reload** rereads a selected app after rebuilding it at the same path. Failed
inputs offer **Retry**. **Reload Both** in the toolbar or Comparison menu
(Shift-Command-R) refreshes both live selections using the explicit architecture.
Old results disappear immediately; failures preserve the URL for retry. Reload
is unavailable for synthetic examples and disabled during reads or report operations.

**Swap** reverses comparison direction. Changing architecture clears both inputs
rather than silently choosing another slice. Replacing or clearing an input
invalidates its old report immediately, including when a previous read finishes late.

**Load Synthetic Example** exercises the interface without reading any installed
app. It produces five changes and one unchanged key. The example is labelled in
the UI and exports and is not a recommended entitlement configuration.

**Copy Report** copies the full change report. **Export JSON** includes both full
snapshots and every change, regardless of filters. Source file URLs are not
exported, but names, signing identifiers, and entitlement values can be sensitive.
Review reports before sharing. Export into a selected app bundle is rejected.

The UI uses native semantic colors, standard controls, keyboard commands, and
selectable monospaced values. Control/bidirectional-formatting characters are
escaped in human-readable displays. Table key/value previews and detail views are
bounded; complete values remain in JSON. See `docs/DESIGN.md` for the layout.

## Reusable libraries

`EntitlementDiffCore` provides typed property-list values, bounded Foundation
conversion, snapshots, comparison, and deterministic tagged JSON/text reports.
`EntitlementDiffModel` owns the session state and injectable asynchronous reader.
`EntitlementDiffSecurity` supplies the macOS Security.framework adapter.

```swift
import EntitlementDiffCore

let previous = EntitlementDictionary(["example.flag": .boolean(false)])
let current = EntitlementDictionary(["example.flag": .boolean(true)])
let comparison = EntitlementComparison(previous: previous, current: current)
assert(comparison.changes.first?.kind == .changed)

let example = ExampleSnapshots.pair(architecture: .arm64)
let report = try ComparisonReport(previous: example.previous, current: example.current)
let json = try report.jsonData()
```

The macOS reader is an actor conforming to `SnapshotReading`:

```swift
let snapshot = try await reader.read(at: applicationURL, architecture: .arm64)
```

Initialize `reader` as `SecurityEntitlementReader()` from `EntitlementDiffSecurity`.
Only conventional local-file-URL `.app` bundles with a Mach-O main executable
are accepted. A file URL can still reside on a network-mounted filesystem; this
is not a guarantee that the underlying storage is physically local.

## Comparison and report contract

Booleans, integers, real numbers, strings, data, dates, arrays and dictionaries
remain distinct. Absent differs from `false`; a missing dictionary representation
also differs from a dictionary that is present but empty. Dictionary order is
ignored; array order and multiplicity are preserved. Keys and string values use
UTF-8 byte identity rather than Swift's Unicode canonical-equivalence equality.

The report uses tagged values. Integers are decimal strings to prevent loss in
JSON consumers limited to 53-bit numeric precision; dictionary entries are sorted
arrays so differently encoded Unicode keys do not collapse. See
`docs/REPORT_FORMAT.md`, `docs/report.schema.json`, and `Examples/`.

This compares the values returned by the system decoder, not the original bytes
of the signature/DER/XML encoding. It cannot recover normalization or information
loss that occurred upstream. Library callers constructing values directly must
provide finite real/date values; JSON encoding rejects nonfinite values.

## Security and privacy boundaries

The production reader invokes public Security/CoreFoundation APIs directly; it
contains no shell, subprocess, plug-in loader, or target-code execution. No custom
history, telemetry, network client, updater, or background scanner is implemented.
macOS may maintain its own panel/recent-location metadata; this tool does not
promise forensic erasure or control system logging.

Successful extraction **does not establish signature validity**. Apple's API can
return partial information from unverified signing data. See `docs/SOURCES.md`.
Inspection is not an atomic filesystem snapshot and is not hardened isolation for
actively hostile inputs. A concurrent writer can defeat filesystem preflights.
Decoder budgets do not bound Apple's earlier parser allocations, and cancellation
cannot forcibly interrupt a synchronous operating-system call. This release is
intended for developer-controlled builds, not bulk malware triage.

## Validation and distribution

This source release reuses accepted local validation receipts. The baseline passed
58 tests in both debug and release, including all eight native integration tests.
Subsequent browser, drop, structured-inspector, inspector-navigation and Reload/Retry changes
passed focused checks and actual local app inspection. The latest affected check
ran five new Reload/Retry methods. These are separate receipts, not a fresh full-suite run
on the release snapshot. See `docs/RELEASE_VALIDATION.md` for evidence boundaries.

Build locally using the commands above. This release does not include an installed
app binary. Local builds are ad-hoc development signed, not Developer ID signed or
notarized. No distribution readiness or complete accessibility acceptance is claimed.
`LICENSE` is MIT.

Notarized arm64 app downloads and source releases: https://github.com/jdotc1/EntitlementDiff/releases/tag/v0.1.1
