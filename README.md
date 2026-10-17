<p align="center">
  <img src="Resources/Icon/Previews/Default.png" alt="EntitlementDiff app icon" width="160" height="160">
</p>

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
`swift run` executable. The Codex **Run** action calls the same script.

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
**All Changes** is the default. **All Keys** shows changed and unchanged keys together.
Category counts describe the full comparison;
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

**View Value…** opens a focused Previous/Current sheet for a scalar leaf. Read long
strings in pages of 512 Unicode scalars or data in pages of 768 bytes (base64),
with explicit page counts and First/Previous/Next/Last controls. Strings escape
control characters. Each side's **Copy Leaf JSON** copies its complete original
typed value regardless of the page; absent/container sides cannot be copied as
leaves. The sheet captures values when opened and disables source actions until
closed. Whole-entitlement Copy Selected JSON remains available.

**Browse Branches** reaches values beyond the search inspector's traversal limit.
It shows up to 50 immediate children per step. Use **Open Branch** to descend,
**Up** to restore the parent page, and **First/Previous/Next Children** to page
through siblings. Arrays also offer **Go to Index** with zero-based indices.
Branch navigation preserves exact Previous/Current pairs without recursively
searching or comparing descendants. **Back to Search** restores the bounded
search view and its incomplete-search notice. Replacing inputs, swapping sides
or selecting a different entitlement resets captured branch navigation.

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

## Saved baselines

Open Saved Report… (Command-O) reviews a schema-1 JSON report and lets you choose
one saved snapshot as Previous. Adoption clears Current and selects the saved
architecture; choose a Current app for a fresh inspection. Saved data is labelled
unverified, has no retained file location or Reload action, and results are
recomputed. Imports are bounded to 8 MiB, 96 JSON levels, 100,000 value nodes and
1 MiB per decoded string. Schema-1 exports remain path-free and retain typed values.
Open Saved Baseline is included in v0.1.4.

## Saved comparisons

The saved-report review also offers Open Saved Comparison, which opens both
validated saved snapshots immediately. Both remain labelled unverified, with no
Reload/Reveal or retained app paths. Either side can be replaced with a live app;
reports remain complete, recomputed and schema 1. Open Saved Comparison is included in v0.1.5. See docs/SAVED_COMPARISON.md.

## Exact key lookup

Find Entitlement… (Command-F) matches a complete key by UTF-8 bytes and selects and
reveals its row. Hidden matches offer explicit Show in All Keys; missing matches
preserve filters and selection. Sorting, full exports and saved provenance remain
unchanged. Find Entitlement is included in v0.1.6. See docs/EXACT_FIND.md.

## Copy exact keys

Copy Exact Key beside the selected detail and in the Comparison menu copies the
current row's complete raw key as plain UTF-8 text. Display quotes/escaping and
preview limits do not affect it. No selection means no copy. Existing JSON/report
copying is unchanged. Copy Exact Key is included in v0.1.7.
See docs/COPY_EXACT_KEY.md.

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

## Incomplete comparisons

The waiting view names missing, loading and failed inputs. Choose the missing
side directly, retry failed inspection when its local source is retained, or open
a saved report. Saved-baseline guidance explicitly asks for a Current app. A failed
inspection never becomes an empty comparison. Included in v0.1.8.

## Inspector projection reuse

Nested inspection retains its projection across unrelated view updates and reuses
rendered row change kinds. Search, expansion, Changes only and paging update it
explicitly. A changed comparison or selected entitlement replaces the session,
including same-key replacement. Existing display limits, exact types and complete
exports are preserved. No measured speedup or bound on full equality is claimed.
Included in v0.1.9.

## Contextual filter recovery

Empty results distinguish zero-key snapshots, matching entitlement values, empty
categories and search-hidden keys. Clear Search preserves category and sort;
Show All Changes or Show All Keys changes only the necessary preferences. Combined
restrictions are named explicitly. Recovery preserves counts and selection rules;
complete schema-1 reports are independent of the view. Included in v0.1.10.

## Downloads and development builds

The published release is **v0.1.10 (build 11)**, including Reload/Retry and Input
Identity. The arm64 app is Developer ID signed and Apple notarized. Download the
app or sanitized source from https://github.com/jdotc1/EntitlementDiff/releases/tag/v0.1.10.
Local development builds are ad-hoc signed and are separate from that published app.
The current local Phase 1 export/source-packaging, comparison/browser computation,
focused-value viewer/copy, branch-navigation and All Keys changes are not in v0.1.2.

Input Details separates bundle and signing identifiers, shows version/build and the
session-only selected location, and offers Reveal in Finder. Optional metadata is
bounded and unverified. Report schema 1 excludes identity metadata and locations.

Accepted baseline and later focused checks are summarized in docs/RELEASE_VALIDATION.md.
The baseline passed 58 methods in both debug and release, including eight native
integration methods. These are reused receipts, not a fresh suite on the current
candidate. docs/MACOS_ACCEPTANCE.md records reuse decisions and remaining limits.
Accessibility work remains stopped. Minimum macOS 14 and Intel-host runtime
acceptance have not been established by the newer Apple-silicon test environment.

Source packaging copies approved tracked working-tree files without rewriting
documentation. See docs/PUBLISHING.md. No automatic hosted CI or publication
workflow is configured. LICENSE is MIT.
