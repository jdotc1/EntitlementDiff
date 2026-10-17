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
(excluding unchanged). All Keys optionally shows changed and unchanged entries
together. Each category shows its total independent of key search.
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

The validated report retains one immutable comparison, reused for UI rows and
excluded from schema 1 by explicit CodingKeys. The session Model owns browser
presentation state: category counts refresh on source replacement; visible rows
refresh on source, query, category or sort changes. Selected-row lookup and view
rendering read this stored projection. Same-ID replacement refreshes values;
selection is reconciled synchronously.

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

## Focused scalar inspection

A scalar-bearing inspector row opens an immutable Previous/Current selection in a
native sheet. Strings are indexed off MainActor into 512-Unicode-scalar pages and
escaped after slicing; data pages hold 768 bytes rendered as base64. Other scalar
types use one page. Preparation is cancelled on dismissal, and each presentation
has independent state. Absent/container sides display context without leaf copy.
Side-specific Copy Leaf JSON uses the original complete value and existing tagged
encoding off MainActor, independently of paging. Source actions are disabled while
the sheet is open, and concurrent copy/dismissal while writing is blocked. Existing
whole-entitlement copy, traversal limits and report schema remain unchanged.

## Explicit branch navigation

Browse Branches provides 50 immediate children per step, paired by exact UTF-8
key or array index. Saved dictionary merge offsets avoid rescanning earlier pages;
arrays allow validated direct index jumps. Open Branch descends one level and Up
restores the parent page. Mixed container types retain separate side structures.
The view does not recursively search or compare descendants. Existing bounded
search and incomplete-search wording remain; full reports/copy are independent.
Branch/page changes reset scrolling. Report revision and selected-key identities
reset captured navigation on source/direction/selection changes. Revision UUIDs
are session-only and never enter exported reports. Child count is bounded; key
byte costs and user-driven ancestor/page history are not constant-memory claims.

## Saved baseline ingestion

Explicit schema-1 import uses bounded container parsing before typed conversion,
strict snapshot validation and recomputation of derived results. Review/adoption
is a separate action; adoption clears live URLs and Current, invalidates pending
reads and selects the saved architecture. Session provenance is excluded from
snapshot CodingKeys and disclosed through the existing report notices field.
See SAVED_BASELINE.md for exact limits and local acceptance boundaries.

## Saved-pair adoption

Open Saved Comparison adopts both snapshots from the validated bounded SavedReport,
invalidates pending reads and live URLs, selects the saved architecture and creates
a new report/navigation revision. Saved labels and report notices remain explicit;
Reload/Reveal require a live URL. Parser and schema-1 encoding remain unchanged.
See SAVED_COMPARISON.md.

## Exact immediate child lookup

Dictionary branches support exact raw UTF-8 key lookup with two binary searches,
one bounded result and existing typed leaf/container actions. Lookup leaves paging
unchanged; Up restores the parent page. Edits/navigation/revision changes clear
results. A narrow native text field preserves canonically equivalent byte-distinct
edits. Branch controls and children scroll together. See EXACT_CHILD_KEY.md.

Find Entitlement and child lookup share the raw-byte ExactKeyField input boundary.
Native edits invalidate prior feedback; Find retains initial focus, Return and
Escape through narrow AppKit callbacks. See UTF8_FIND_INPUT.md for the confirmed
canonical-equivalence input defect and focused correction.
