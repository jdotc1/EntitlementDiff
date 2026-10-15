# EntitlementDiff

EntitlementDiff is a lightweight Swift library and native SwiftUI macOS application
for comparing embedded entitlement declarations between builds. It helps developers
review changes in declared application capabilities without launching the inspected
application.

Choose a previous and current `.app`, select **arm64** or **x86_64**, and inspect
added, removed, changed, and unchanged entitlements. Unknown keys remain visible;
the tool does not assign risk scores or interpret an entitlement as proof of a
vulnerability.

**Scope:** the requested architecture of the main executable only. No nested-code
audit, signature verification, Gatekeeper assessment, notarization check, or
claim about effective permissions.

## Reviewing entitlement changes

EntitlementDiff preserves property-list types rather than flattening values into
strings. Booleans, numbers, strings, arrays, and dictionaries remain distinct; an
absent entitlement is not treated as equivalent to an explicit `false` value.
Nested values can be inspected side by side.

Structured JSON exports include both snapshots and the complete comparison,
regardless of the current interface filters. Reports provide a record of the
declared changes for release reviews, build investigations, and subsequent
analysis—not an automated security verdict.

### Example review workflow

The following is an illustrative workflow, not a reported finding.

Compare two builds of an application you control, using the same architecture for
both. Suppose the newer build contains an additional entitlement or changes an
existing Boolean declaration from `false` to `true`.

Review the exact key and typed values, then investigate whether the difference
corresponds to an intended feature, a build-configuration change, or a
signing-configuration change. Record the explanation alongside the exported
comparison.

The difference establishes that the extracted declarations changed. It does not,
by itself, establish that the application gained an effective permission,
exercised a capability, or introduced a vulnerability. Those questions require
separate investigation.

## Downloads and development builds

[Version 0.1.2](https://github.com/jdotc1/EntitlementDiff/releases/tag/v0.1.2)
provides a Developer ID–signed, hardened-runtime, Apple-notarized and stapled
application for Apple silicon running macOS 14 or later, alongside a source
archive containing the Swift package, tests, examples, and resources.

- [Download the Apple-silicon app](https://github.com/jdotc1/EntitlementDiff/releases/download/v0.1.2/EntitlementDiff-0.1.2-macOS-arm64.zip)
- [Download the source archive](https://github.com/jdotc1/EntitlementDiff/releases/download/v0.1.2/EntitlementDiff-0.1.2-Source.zip)

Local builds created with the development scripts are ad-hoc signed and should
not be confused with the published notarized application. The signing and
notarization of EntitlementDiff's published app do not mean that the tool verifies
the signature or notarization of an application it inspects. See the validation
section below and `docs/RELEASE_VALIDATION.md` for the documented evidence limits.

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
snapshots and every change, regardless of filters. Export into a selected app
bundle is rejected. See Reports and privacy below before sharing an export.

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

## Security scope and limitations

EntitlementDiff compares declarations; it does not verify the validity or trust
of the inspected application's signature. Successful extraction **does not
establish signature validity**. Apple's API can return partial information from
unverified signing data. See `docs/SOURCES.md`. Declared entitlements are not a
complete account of effective permissions or runtime behavior.

Inspection is limited to the selected architecture of the main executable. The
tool does not audit nested helpers, frameworks, extensions, or other embedded
executables. It does not perform Gatekeeper assessments, check the inspected
application's notarization status, assign risk scores, or classify entitlement
changes as vulnerabilities.

The production reader invokes public Security/CoreFoundation APIs directly; it
contains no shell, subprocess, plug-in loader, or target-code execution.
Inspection is not an atomic filesystem snapshot and is not hardened isolation for
actively hostile inputs. A concurrent writer can defeat filesystem preflights.
Decoder budgets do not bound Apple's earlier parser allocations, and cancellation
cannot forcibly interrupt a synchronous operating-system call. This release is
intended for developer-controlled builds, not bulk malware triage.

## Reports and privacy

Exported reports omit source file URLs but retain application names, signing
identifiers, and entitlement values. Review this information before sharing a
report, particularly when inspecting internal or unreleased applications.

No custom history, telemetry, network client, updater, or background scanner is
implemented. macOS may maintain its own panel/recent-location metadata; this tool
does not promise forensic erasure or control system logging.

## Input Identity and Build Metadata

Source panes show version/build. Input Details separates bundle and signing
identifiers and shows the selected location, with Reveal in Finder. Optional fields
are bounded and unverified. Locations stay session-only; report schema 1 and
export bytes are unchanged.

## Validation

This source release reuses accepted local validation receipts. The baseline passed
58 tests in both debug and release, including all eight native integration tests.
Subsequent browser, drop, structured-inspector, inspector-navigation and Reload/Retry changes
passed focused checks and actual local app inspection. Input Identity and Build Metadata passed six new focused methods and native
selection, details, Finder reveal, reload and Swap inspection. The latest affected
checks preserve report schema 1 and unchanged report bytes. These are separate receipts, not a fresh full-suite run
on the release snapshot. See `docs/RELEASE_VALIDATION.md` for evidence boundaries.

The [v0.1.2 release notes](https://github.com/jdotc1/EntitlementDiff/releases/tag/v0.1.2)
document stapled-ticket validation, Gatekeeper assessment, and native release-app
inspection on the same Apple-silicon Mac. This is not clean-Mac or Intel-host
acceptance. Complete accessibility acceptance is not claimed.

## About the developer

I'm a physician-scientist and independent developer focused on medical imaging
and software security. I build and modernize medical-imaging and scientific
software for Apple silicon and native macOS, with particular attention to
security hardening, reliable data handling, and binary analysis.

EntitlementDiff applies that focus to a specific developer workflow: reviewing
and documenting changes in declared application capabilities.

## License

`LICENSE` is MIT.
