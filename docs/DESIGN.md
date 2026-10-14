# EntitlementDiff — design specification

## Intent and scope
Build a small, native macOS utility and reusable Swift libraries that compare the
embedded entitlement declarations of two local application builds. It is a
read-only metadata comparator, not a trust evaluator or an effective-permissions
auditor. Keep it independent of MacScope. No third-party dependencies.

## Platform and products
Swift 6 language mode; tools version 6.0; macOS 14 or later. A SwiftPM workspace
is the source of truth. Portable Core and Model libraries have Linux tests.
The Security adapter and SwiftUI app exist only in macOS package graphs. A local
script stages a real .app bundle; no fabricated Xcode project is required.

## User workflow
One window, previous/current selectors, a shared explicit architecture picker
(arm64 or x86_64), and a Compare result table. Each source pane also accepts one local .app URL via native dropDestination.
Drop-envelope errors preserve existing inputs; accepted URLs use the same
ComparisonModel.load path and selected architecture as panel selections.
The reader retains full bundle/signing/architecture validation. Selection triggers read-only
inspection; comparison appears only when both reads succeed. Show Added,
Removed, Changed or Unchanged through a category picker, defaulting to All Changes
(excluding unchanged). Each category shows its total independent of key search.
A shown-row count combines category and key search. Change and Entitlement headers
sort in both directions, using UTF-8 bytes for deterministic key identity/order.
Reset View restores All Changes, empty search and ascending key order. Selection
persists while its row remains visible; hiding/removing it clears selection.
A search field filters keys. Selecting
a row reveals bounded typed previews; exports retain complete values. Copy a complete text report or export
complete deterministic JSON; filters never silently reduce the export.
A built-in synthetic example makes the UI reviewable without external apps.
Swap is disabled while loading. Clear or changing architecture invalidates all
in-flight results. Replacing an input removes its previous snapshot immediately.

## Inspection contract
Inspect only the requested architecture of the main executable. Use the public
Security framework with explicit architecture attributes; never fall back to
another architecture or claim to inspect every slice, helper, extension, or XPC
service. Validate the .app layout and a Mach-O magic prefix, then positively discover
the requested CPU family using CFBundleCopyExecutableArchitecturesForURL on the
exact executable. Security architecture attributes can be ignored for non-Mach-O
inputs. CPU subtypes are not separately enumerated in v0.1. No code from
the selected app is executed. The adapter does not invoke a shell or subprocess.
Canonicalize URLs after acquiring any security-scoped access; balance access
with defer. Reject bundle metadata or main executables that resolve outside the
selected bundle. This preflight is not a race-proof filesystem sandbox.

Signature extraction and signature verification remain separate. A missing
signing identifier is an unsigned-input error, not an empty entitlement set.
A raw entitlement blob without a decoded dictionary is an unsupported-format
error, not no entitlements. Distinguish an absent entitlement representation
from an explicitly empty dictionary. Corrupt or unreadable inputs produce errors.
Do not infer validity from a successful read: Apple can return partial information.
Use default signing-information flags, avoiding certificate/trust assessment.

## Data fidelity
Preserve Boolean versus integer, signed 64-bit and large unsigned integers,
finite real values, strings, data, dates, arrays, and nested dictionaries.
Integers export as decimal strings inside tagged JSON objects to avoid 53-bit
consumer precision loss. Dictionary order is immaterial; array order and
multiplicity are significant. Compare strings and keys by UTF-8 bytes rather
than Swift's canonical-equivalence String equality. Reject exact duplicate keys
at model boundaries. Unknown keys are retained, not scored or interpreted.

The Foundation decoder has explicit nesting, node, and decoded byte budgets.
These limit our conversion, not allocation or execution inside Apple's parser.
Nonfinite numbers/dates, decimal-number subclasses and unsupported types fail
explicitly. Signing identifiers have a separate 4,096-byte UTF-8 policy limit. UI/report text
escapes control and bidirectional-formatting characters; exports retain original
values. No input file paths appear in reports; bundle names and entitlement
values can still be sensitive. No timestamps or random IDs enter the report.

## Architecture
- EntitlementDiffCore: typed values, bounded Foundation conversion, immutable
  snapshots, exact comparison, deterministic tagged JSON and text reports.
- EntitlementDiffModel: MainActor observable state and cancellable request
  orchestration against an injectable Sendable async reader.
- EntitlementDiffSecurity: serial actor wrapping synchronous native inspection.
- EntitlementDiffApp: one native SwiftUI Window, semantic styles, standard Table,
  detail pane, file/save panels, keyboard commands, explicit error/loading states.

Use generation tokens as well as Task cancellation: Security calls are
synchronous and cannot be forcibly interrupted. Never accept a late result for a
superseded selection. Perform synchronous inspection off the MainActor.

## Explicit exclusions
No signature validation, Gatekeeper/notarization verdicts, TCC inspection,
permission granting, remediation, root helpers, system extensions, live process
inspection, monitoring, app database, persistent history, network client,
telemetry, auto-updater, broad entitlement glossary, nested code traversal, or
automatic architecture fallback. An ad-hoc local bundle is not a distributable
notarized release. No automatic hosted-macOS CI or GitHub writes.

## Acceptance
Portable tests must exercise type fidelity, deterministic export, dictionary and
array semantics, limits, escaped display, comparison direction, state invalidation,
late-result suppression, errors, swapping and examples. Native integration tests
must build synthetic local app fixtures and test the Security framework without
launching them. Include a local macOS verification script and visual/keyboard/
accessibility checklist. Label unexecuted macOS checks honestly. Perform a
separate adversarial review pass, add regression tests for confirmed findings,
and preserve a finding/disposition record. Package sources, tests, plans,
review, actual evidence, and Codex instructions in a single ZIP.

## Native layout and display budget

```text
EntitlementDiff                           Swap   Copy Report   Export JSON
Compare embedded entitlements                        Architecture [arm64]
[ Previous: Choose/Replace, identity ] [ Current: Choose/Replace, identity ]
Main executable only; no signature/Gatekeeper/notarization validation
Filter entitlement keys   Show [All Changes]  Reset View   shown / total counts
Change         Entitlement                 Previous          Current
-----------------------------------------------------------------------
Selected key / change kind
Previous typed value                      Current typed value
-----------------------------------------------------------------------
Privacy / operation status                                      Clear Both
```

Single Window, default 1120 × 800, minimum 880 × 650. Native Table and vertical
split details; semantic light/dark styles and standard system fonts. Table value
previews allow 160 Unicode scalars; table keys/tooltips allow 512; detail keys and
values allow 16,000. A truncation marker can add one scalar. Key headings may be
visually line-limited; exports preserve complete keys/values. A scalar budget is
intentional because one grapheme can contain arbitrarily many combining marks.
No custom color palette or fabricated screenshot is needed for the source handoff.

## Reviewed implementation refinements

The observable model owns a constant InspectionRequests container for nonobservable
bookkeeping. That container cancels remaining tasks on destruction. The portable
state logic is unchanged when Observation annotations are excluded on Linux; a
separate typecheck enables them without linking the defective installed Linux
Observation runtime. See RELEASE_VALIDATION.md for the reproduced initial macro failure.

The report destination guard resolves existing parent directories before a new
filename and checks both input bundles. It reduces accidental mutation but does
not provide a filesystem capability boundary under concurrent adversarial writes.
The intended first audience is developers comparing their own controlled builds,
not a hostile-file analysis service.

## Current structured inspector navigation

Selected values use a paired expandable dictionary/positional-array tree. Nested
path search opens collapsed descendants within 2,000 visited nodes and 12 levels,
retaining ancestor context; Changes only removes unchanged subtrees. UI paging
shows 50 rows, with Previous Page / Reveal More and explicit incomplete-search
notices. Key/value previews are capped at 256 scalars; composite path previews at
512. Selected JSON remains complete and tagged. These supersede the historical
flat 16,000-scalar detail description above. See RELEASE_VALIDATION.md.

## Explicit input refresh

Live inputs support Reload/Retry through the same load path and selected architecture.
Reload Both captures both source URLs and invalidates both prior snapshots without
suspension. Failed inspections retain source URLs for explicit retry; synthetic
examples have none. Generation checks/cancellation suppress superseded results.
UI disables refresh while reading or presenting/writing a report. No persistent
history or monitoring. See RELOAD_INPUTS.md.

## UI input identity metadata

Optional bundle identifier, version and build are bounded display information from
the existing validated Info.plist preflight. They accompany the accepted snapshot
but are excluded from Codable report fields. Selected URLs remain session-only.
Input Details separates bundle/signing identifiers and reveals the selected item
in Finder. Metadata is unverified; requested architecture and main-executable-only
inspection remain explicit. See RELEASE_VALIDATION.md.
