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
and preserve a finding/disposition record. Package source, tests, public design
and release-validation records together; keep workstation evidence separate.

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

Focused leaf panes support independent explicit one-based page jumps using the
existing document index. Invalid input preserves the page; editing clears range
feedback. Existing navigation synchronizes the field, and new presentations reset
all state. Rendering limits and complete copying are unchanged. See LEAF_PAGE_JUMP.md.

Browse Branches can copy each complete current container side as tagged value JSON.
Encoding runs off-main from immutable captured values, with revision/selection
guards and busy navigation/selection blocking. Empty containers remain valid;
absent/scalar sides are disabled. This is a value fragment, not a schema-1 saved
report. Rendering/full report contracts are unchanged. See COPY_BRANCH_JSON.md.

Browse Branches offers Root and at most12 nearest non-root ancestors. Opaque
frame destinations restore saved cursor/page history without parsing labels or
searching descendants; stale destinations are rejected and lookup input cleared.
Existing revision/selection resets apply. See ANCESTOR_NAVIGATION.md.

Focused string panes offer independent explicit literal UTF-8 search, with1,024-byte
queries and32KiB steps, continuation, overlapping Find Next and nonwrapping end.
Original byte/scalar offsets navigate to the start page without changing rendering
limits or complete copying. Cancellation plus query/session generations suppress
stale publication. No data/base64 search. See FOCUSED_STRING_SEARCH.md.

Focused string rendering maps the original match byte range into escaped UTF-16
ranges for the selected512-scalar page. A narrow read-only NSTextView bridge uses
semantic selected-text colors and reveals the start on a new match revision or
page. It never assigns the match as the user's text selection or changes focus.
Page byte offsets are indexed off-main alongside existing scalar page ranges;
rendering visits only that page. Query clearing removes styling/pending reveal;
teardown drops pending layout work. Existing search generation/cancellation guards
remain authoritative. Cross-page portions have explicit continuation guidance.

StringValueSearch retains a last-match UTF-8 index and original byte/scalar offsets.
Direction switching excludes the current start, includes overlapping occurrences,
and moves at most1,024 bytes near that anchor. A bounded reversed KMP pattern
scans backward in32KiB explicit steps, carrying partial multibyte matches. It never
materializes full source bytes or rescans a prefix to locate its anchor. Model
direction changes cancel prior work and replace generations, including a deliberately
late return. Each pane has its own cursor/direction; Find restarts forward. Reaching
an endpoint disables only that direction. Query edits/dismissal clear both directions.
See FOCUSED_STRING_SEARCH.md. Highlight bridge coordinator is explicitly MainActor.

Focused string pairs support an explicit first-difference cursor over original
Unicode scalars, with no normalization, text alignment or complete byte arrays.
Each step reserves room for a scalar pair before reading, consuming at most32KiB
combined source UTF-8 bytes, and checks cancellation every64 pairs. Indices,
common-prefix byte/scalar offsets and immutable sources persist across continuation.
A MainActor session publishes only for its generation; dismissal/restart invalidate
old output. The first differing scalar (or end boundary) drives both existing page
navigators, clamped independently at EOF. Only its bounded escaped page is styled.
EOF marks the closing quote with an explicit label. Find cursors/results remain
independent; latest explicit Find/difference reveal chooses the displayed highlight.
Reveal Difference republishes a presentation revision without comparing again.

First-difference positions retain the two numeric Unicode scalars (or nil for EOF)
read by the existing bounded cursor. Byte counts derive from those scalars, avoiding
inconsistent scalar/count metadata. StringScalarDetail formats U+ notation, explicit
Unicode escapes and up to four UTF-8 bytes without touching the source strings.
EOF is an explicit End of string label without scalar/byte placeholders. Pane detail
rows refer to the saved first difference even when Find shows a separate match;
the existing scalar/byte position remains in the comparison summary. The same
position publication/generation owns details, highlight and reveal. No report/schema
change, source rescanning, additional comparison step or raw invisible label glyphs.

Focused data pairs use a separate DataFirstDifference cursor over original Data
indices (including sliced Data with nonzero start indices). At most32KiB combined
input bytes are read per explicit step, with cancellation every256 pairs. A mismatch
captures the exact optional bytes; nil denotes EOF, distinct from00. Page offsets
remain relative to the captured value and map to existing768-byte base64 pages.
A MainActor data session owns detached work, cancellation and request generations;
restart/dismissal invalidate prior results. Display preparation can finish after a
result and still navigate correctly. Reveal Difference changes only presentation
revision, resets the data page viewport, and clamps EOF independently per side.
No base64 character is marked as an individual original byte. Mixed/non-data pairs
have no data-comparison action; string search/comparison, complete copying and
schema-1 reports retain their existing contracts.

DataDifferenceContext is a fixed window over captured original Data. It reads at
most33 bytes per side (16 before, one target,16 after), using relative offsets
mapped through startIndex. EOF has a bracketed marker and no fabricated byte;
empty/beginning/end windows clamp independently. Hex strings and range labels
are prepared once when the data result passes its cancellation/generation guard.
No added full-value copy, base64 decode, prefix scan or per-body formatting occurs.
The narrow DataHexContextView displays this immutable result; existing base64
page navigation and complete typed-copy/report contracts are unchanged. Context
clears with the result and survives manual paging/Reveal Difference unchanged.

Focused data Find Next Difference advances both native Data indices past the
already-read mismatch in constant work; it never rescans the prefix. The existing
step method retains the current result until explicitly advanced. A prefix EOF
is emitted once, then the cursor is exhausted without walking unmatched trailing
bytes. This is positional byte comparison, not insertion/deletion alignment.
The MainActor session retains the last result/context during next-search portions;
publication requires cancellation and generation guards. Every new result updates
ordinal, exact byte/EOF details, fixed context and reveal revision together.
A separate finished phase means No further differences; equal remains reserved
for a fully equal pair. Next is disabled while paused/running/finished. Explicit
Continue Comparison resumes paused work; Find First Difference resets the cursor,
ordinal and context. String behavior and complete report/copy contracts unchanged.

StringFirstDifference now retains independent native scalar cursors and UTF-8
byte offsets for Previous/Current. Position.byteOffset remains the Previous
compatibility offset, previousByteOffset names it explicitly, and currentByteOffset
tracks Current. Equal-prefix first results retain prior coordinates. Advancing
past a saved mismatch updates each offset by its own scalar width; later page
highlight mapping uses the side's offset. Scalar position/page remain shared
because comparison advances one scalar per side, with no normalization or inferred
alignment. EOF marks exhaustion once, without walking the unmatched suffix.
FocusedStringDifference starts next under a fresh generation, retains old details
while paused, and atomically publishes ordinal/scalars/coordinates/reveal revision.
Finished differs from equal; Next never wraps. Existing literal Find state,
complete copies, data inspection and schema-1 reports retain their contracts.

FoundDifferenceHistory retains at most64 compact position/ordinal entries, never
source values or cursor snapshots. A session keeps one frontier cursor while its
displayed history index can move backward/forward. Only frontier scanning appends;
eviction drops the oldest entry and exposes the earliest retained ordinal. Saved
replay does not invoke the comparison runner. String scalar/per-side UTF-8 details
are restored exactly; data hex context is regenerated with its existing fixed
33-byte-per-side bound. Reveal revision reuses existing page/highlight mapping.
Frontier completion is independent of displayed result: moving backward from a
finished comparison and forward again restores finished without rescanning.
Previous/Next require settled phases; paused/running work cannot navigate history.
Every navigation/new request invalidates old generations and cancels prior work;
accepted new results alone populate history. Restart/dismissal replaces history.
No report, copy, parser, architecture, dependency or source-value contracts change.
