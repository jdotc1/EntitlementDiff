# All Keys addition — 2026-10-15

Added All Keys after All Changes in the existing Show picker. All Keys includes
all four change kinds, including unchanged entries. It retains the existing raw
key search, deterministic sorting and selection reconciliation. Its category count
uses the complete source row count, independent of search. All Changes remains the
initial preference and Reset View default. No report/inspection schema change.
The earlier browser record below remains historical; the stored projection/counts
refactor is documented in SHARED_COMPARISON.md.

`swift test --filter 'ComparisonBrowserTests/testAllKeys' -Xswiftc -warnings-as-errors`
passed two new methods once (evidence/151-all-keys-focused-tests.log). They cover
all kinds, default/reset, cached/stateless agreement, change sorting with unchanged
rows, search-independent totals, hidden-selection clearing, empty/replaced source
counts and byte-distinct unchanged Unicode keys. Existing tests were not rerun.

`./script/build_and_run.sh` built/launched the actual development app (152). Native
checks (153) observed All Changes (5) initially, All Keys (6) showing all six rows,
selection of unchanged app-sandbox, search reducing shown rows to one while All
Keys remained six, and Reset View returning to five changed rows with empty search
and cleared detail. No crash/hang observed; no new runtime-log or fault-free claim.

Scoped source review checked enum enumeration, count/selection paths, empty-state
behavior and unchanged default/reset preferences; no consequential issue found.
This small change was reviewed locally, with no independent reviewer claim. Reuse
accepted browser 41–43/133–138 and unchanged report/native-reader/inspector evidence.
No full suite, eight native reader rerun, unchanged check repeat, new dependencies,
accessibility work, signature verification, Applications update, release or push.
The build script's ordinary ad-hoc signing step is not distribution verification.

---

# Comparison browser milestone — 2026-10-14

Implemented the user-approved bounded milestone: change-type filters, category and
shown counts, sortable native headers, reset and selection continuity. Accessibility
work remains stopped; existing accessibility features were preserved. Computer Use
state reads served functional interaction confirmation, not an accessibility audit.

## Implementation

ComparisonBrowser in EntitlementDiffModel holds view-only preferences and selection.
All Changes excludes unchanged by default. Added/Removed/Changed/Unchanged combine
with raw-key case-insensitive search. Category counts use the full comparison.
BrowserSort conforms to Foundation SortComparator; Change order is Added, Removed,
Changed, Unchanged, with UTF-8 key tie-breaking. Entitlement order is UTF-8 byte
order; reverse order is deterministic. Existing Base64 byte-key IDs remain stable.
Native Change/Entitlement TableColumn sortUsing comparators drive bound sort state.
Reset View restores the default filter/search/sort without unnecessarily clearing
visible selection. An onChange of visible row IDs clears selection once hidden or
removed, preventing an old detail from reappearing when a filter is reset.

No reader, decoder, comparison algorithm, report serializer, panels/write boundary,
platform/dependency/signing policy or accessibility feature changed. No persistent
history, trust assessment or online feature added. All new code stays in this repo.

## Focused executed evidence

- `swift test --filter ComparisonBrowserTests -Xswiftc -warnings-as-errors`
  exited 0; three new test methods passed (evidence/41-comparison-browser-tests.log).
  Other test products reported zero selected tests. No full suite executed.
  Covers category/search counts, immutable source row count, key reverse order,
  change grouping/reverse, byte-distinct canonically equivalent Unicode keys,
  sorting selection continuity, hidden/removed selection clearing and reset.
- `./script/build_and_run.sh --verify` exited 0
  (evidence/42-comparison-browser-build-launch.log). Built actual app, staged and
  ad-hoc signed changed development bundle, launched and observed process.
  No repeated standalone signature verification was performed.
- Native functional inspection observed default All Changes (5), Added (1),
  Removed (1), Changed (3), Unchanged (1); five shown/five changes/one unchanged.
  Selecting parser-version then reversing Entitlement order kept typed detail
  1→2 selected while rows reversed. Change header grouped rows Added/Removed/Changed.
  Changed category showed three; search parser reduced shown to one while totals
  stayed five/one and category stayed Changed (3). Search no-match showed the
  explicit filter-empty message and cleared details. Reset cleared search/category/
  sorting, restored ascending five rows, and did not resurrect hidden selection.
  Unchanged category showed the single app-sandbox row. Reset restored defaults.
  Default-size screenshot showed native semantic styling and usable control layout.
- `/usr/bin/log show --last 8m --style compact --predicate 'process ==
  "EntitlementDiff" AND messageType == fault'` retained in evidence/43.
  Negative-width/height AppKit geometry messages recur during native inspection.
  Existing GEOMETRY_DIAGNOSTIC.md / evidence/38 localize that observed message to
  system sharing-indicator sizing. No new stack diagnosis or blanket clean-runtime
  claim is made. No crash/hang was observed during this functional inspection.

Public native TableColumn sortUsing declaration was checked in the selected
macOS 27.2 SDK SwiftUI.swiftinterface (around line 4636). Deployment remains macOS
14 and Swift 6 mode. SwiftUI Specialist row identity guidance was applied.

## Reuse and boundaries

Reuse evidence/32 for unchanged Core/native extraction and established model logic,
prior report/export receipts (34/35 and EXPORT_ACCEPTANCE.md) for unchanged report
encoding/writes. Those historical whole-suite receipts are not presented as a new
whole-suite pass for the modified tree. Only the three new tests ran. No release
suite, source/export hash, dependency/signature reverification, corpus run, hosted
CI or online push. No independent reviewer pass on this milestone is claimed.
App left running in default synthetic All Changes view. Distribution readiness,
other-host validation and stopped accessibility work remain outside this milestone.
