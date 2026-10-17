# Accepted local validation summary

- Original macOS baseline: 58 tests in debug and 58 in release, including eight
  native integration methods. Native compilation and local development signature
  verification passed on Apple silicon, macOS 27.2 beta, Apple Swift 6.4.
- Comparison browser: three new focused methods passed and local UI inspected.
- Application drop: six new focused policy/action methods passed. Real Finder
  drops into both panes, explicit architecture rejection and invalid-file recovery
  were observed. Native multiple-file gesture and held-hover outline were not
  separately accepted; multiple-input rejection has focused test coverage.
- Structured inspector: three focused methods passed and local UI inspected.
- Reload/Retry: five new focused methods passed; changed-fixture reload, failed
  input recovery and Reload Both were inspected in the actual development app.
- Input identity: six new focused methods passed, including native metadata refresh,
  bounds/type checks, unchanged report bytes/schema and stale-result continuity.
  Same-named inputs, Finder reveal, changed/malformed metadata reload and Swap
  were inspected in the actual development app.
- Inspector navigation: six affected methods passed (three new, three existing),
  and rebuilt app search, paging, filtering and complete filtered JSON copy were
  inspected. No full-suite rerun occurred after the baseline.

Raw workstation logs, screenshots, handoff archives, personal agent instructions
and local Git history are excluded. The local audit retains those accepted receipts.
This summary is not a new test run, independent release audit or binary-distribution
qualification. Accessibility work was explicitly stopped; complete acceptance is
not claimed. AppKit sharing-indicator geometry faults were previously localized to
system stacks; no product fix or fault-free-runtime claim follows.

## Local Phase 1 delta (2026-10-14)

Export validation now retains destination-entry ancestry as well as the resolved
target. One new synthetic policy regression failed before the fix; all four
focused destination methods then passed on macOS. Real development app built and
launched. An ordinary native save-panel export created the selected JSON file.
This is preflight protection, not a race-proof filesystem guarantee.

Version-aware source packaging now copies documentation unchanged, rejects
unresolved/non-regular selected index entries and requires current release/reload/
acceptance documents. Five unchanged supplied manifest methods reuse their accepted
Linux receipt; two temporary-file methods adapted for resolved macOS roots passed.
Three new cleanup/refusal methods passed across their scoped initial/corrected runs.
No real release was repackaged. See MACOS_ACCEPTANCE.md for evidence boundaries.

These checks were local Phase 1 evidence. The changes are included in the v0.1.3
release candidate. Distribution receipts are separate from this source summary.

## Local comparison/browser computation delta (2026-10-15)

One validated comparison now supplies both report and UI rows. Browser category
counts and visible rows are retained between relevant source/preference changes.
Eleven distinct focused methods passed across the scoped runs, including unchanged
example JSON/text bytes, Unicode ordering, selection, same-ID replacement, Reload
and invalidation. A reviewer-found stateless selection regression was reproduced
before its fix and passed afterward. Unaffected accepted results were reused.

The real development app built/launched and native filter, selection, Swap,
Reset, sorting and category behavior were inspected. No native speedup benchmark
or full suite was run. Runtime logs retained system-service messages and AppKit
geometry faults; no new product attribution or fault-free-runtime claim follows.
Accessibility remains stopped. No signature verification, release operation,
Applications update or publication occurred; recorded distributed v0.1.2 is unchanged.

## Local focused-value delta (2026-10-15)

Seven new focused methods passed across the initial and single corrected-test
runs. One signed-zero assertion required a typed Double decoder; production
encoding was unchanged and the other six accepted passes were reused. Coverage
includes bounded text/data pages, suffix reachability, exact typed leaf payloads,
byte-distinct keys, captured sides, absent/container refusal and failure recovery.
The real staged development bundle built and launched. Native inspection showed
both differing third-page suffixes, complete 1,331-character Current clipboard
JSON from that page, dismissal and fresh one-page/absent-side selection behavior.
A bounded independent source review found no consequential defect. Runtime logs
retain AppKit geometry and system-service messages; no new diagnosis or fault-free
claim. No full suite or native reader rerun, performance/compatibility campaign,
accessibility work or distribution acceptance. These changes are local and are
not included in v0.1.2; existing release/install receipts remain unchanged.

## Local branch-navigation delta (2026-10-15)

Five new focused methods passed once: later array/dictionary navigation, UTF-8
identity, 20-level descent, parent-page restoration, mixed/empty values and source
revision invalidation. Explicit navigation reached native array index 2099 beyond
the incomplete-search prefix and opened the correct exact leaf. Copy completion
was observed, but a subsequent clipboard byte check was inconclusive; existing
accepted leaf encoding evidence is reused. A native scroll-position regression
was recorded before a view-only repair; rebuilt branch entry and next-page scroll
checks passed. Swap discarded old navigation state. No unchanged tests reran.
A separate bounded source review found no consequential issue. Runtime logs
retain AppKit geometry/system-service messages; no fault-free claim. Search and
whole-export semantics remain unchanged. No full suite/native-reader rerun,
benchmark, minimum-OS/Intel acceptance, accessibility work or distribution action.
These local changes are not included in published/installed v0.1.2.

## Local All Keys delta (2026-10-15)

Two new focused methods passed once for all-kind inclusion, full category counts,
search/sort/selection/reset, empty/replaced sources and distinct Unicode keys.
The real development bundle built and launched. Native selection of All Keys
showed all six synthetic rows; key search reduced shown rows without changing its
count; Reset View restored the default All Changes and cleared hidden selection.
Accepted unaffected evidence was reused, with no full suite, native-reader rerun,
accessibility work or distribution action. No new fault-free-runtime claim. The
installed/published v0.1.2 does not include this local change.

## v0.1.3 accepted feature evidence

- Shared comparison/browser projection: eleven distinct focused methods passed
  across initial and compatibility-repair runs; native filter/selection, Swap,
  Reset and reverse sorting inspected. Schema 1 byte fidelity retained.
- Focused long values: seven new methods passed across initial/corrected oracle
  runs; native bounded paging, suffix visibility, copy completion and selection
  replacement inspected.
- Branch navigation: five new methods passed; native beyond-limit navigation,
  paging/reset and scroll correction inspected. Clipboard byte acceptance was
  unavailable during one branch session; UI completion alone was observed there.
- All Keys: two new methods passed; native All Keys, search and reset inspected.

These are reused focused receipts, not a full suite on the release candidate.
AppKit system geometry messages remain recorded without a fault-free claim.
Accessibility stays stopped. Minimum-OS, Intel-host and clean-Mac runtime
acceptance remain unestablished.

## Open Saved Baseline — accepted feature evidence

Four new bounded parser methods passed, covering typed values, Unicode identity,
schema fields, untrusted derived claims, invalid inputs/invariants and parsing
budgets. Two model methods passed after correcting an unnecessary try in test
source; adoption invalidates pending reads and Current, clears URLs, sets the
architecture and carries saved provenance through Swap. The development app
built/launched; native report review, explicit snapshot selection/adoption, fresh
Current selection, schema-1 path-free export and failed-import recovery passed.
These focused receipts are reused for v0.1.4; no full suite was rerun.

## Open Saved Comparison — accepted feature evidence

Two new model methods passed, covering saved-pair adoption, pending-read suppression,
architecture/navigation invalidation, counts, complete JSON fidelity, filtering,
Swap, saved/live replacement and path-free schema 1. The real development app
built/launched. Native review, opening both saved snapshots, array inspection and
live Current replacement passed. Parser/Core encoder were unchanged. These focused
receipts are reused for v0.1.5; no full suite was rerun. Accessibility remains stopped.

## Find Entitlement — accepted feature evidence

Three new focused methods passed across initial lookup and report-fidelity runs.
They cover visible/missing/hidden keys, explicit reveal, sorting/counts, UTF-8
identity, whitespace/empty keys, replacement, complete JSON and saved provenance.
The real development app built/launched. Native 100-row acceptance selected and
scrolled to the final row, confirmed hidden-key reveal, and preserved selection
and filters on a missing lookup. These receipts are reused for v0.1.6. No full
suite was rerun; accessibility remains stopped.

## Copy Exact Key — accepted feature evidence

Three new focused methods passed, including raw UTF-8 fidelity on a unique named
native pasteboard, current selection/filter/clear/busy guards, clipboard failure,
unchanged complete report JSON and saved provenance. Unicode variants, whitespace,
control characters, empty keys and keys beyond preview limits were covered. The
real app built/launched; native button/menu copy pasted correct unquoted keys into
Find, including after selection changed. These receipts are reused for v0.1.7.
No full suite was rerun; accessibility remains stopped.

## Comparison guidance — accepted feature evidence

Five new focused methods passed for empty, one-sided, saved-baseline, loading,
failed-input and report-error presentation, including retained-source Retry policy.
The real development app built and launched. Native empty/saved-baseline/failure
layouts, contextual saved-report and app pickers, completed comparison, missing
Previous guidance and failed-input Retry were accepted. Loading and both-failed
states have focused model coverage, not separate native visual acceptance. These
receipts are reused for v0.1.8. Reader, generations, typed values, report encoding
and browser behavior are unchanged. No full suite; accessibility remains stopped.

## Inspector Projection Reuse — accepted feature evidence

Eleven distinct focused methods passed: five new session/regression methods and
six existing inspector methods covering the changed construction path. An introduced
absent/absent Changes-only case failed its new assertion regression before a narrow
fix, then passed its scoped rerun. Real development app builds and native typed
rows, collapse, bounded search, paging, Changes only and same-key Swap invalidation
were accepted. These receipts are reused for v0.1.9. Branch listing retains lazy
classification; native-read generations, types, reports and export boundaries are
unchanged. Display bounds do not bound recursive equality time. No measured speedup
is claimed. No full suite was rerun; accessibility remains stopped.

## Contextual Filter Recovery — accepted feature evidence

Five new focused methods passed for search/category/combined/no-change/zero-key
recovery, nondefault sorting, counts, selection reconciliation, stale-action guards,
UTF-8/type fidelity and byte-identical complete schema-1 report JSON. The real app
built and launched. Native search recovery restored descending rows; Show All Keys
revealed unchanged keys; combined restrictions recovered to available changes;
zero-key saved snapshots retained provenance and offered no misleading action.
Final count wording was refined and compiled without behavioral changes; accepted
flows were reused. These receipts are reused for v0.1.10. Reader, parser, report
encoding and export boundaries are unchanged. No full suite; accessibility stopped.

## Finder report opening — accepted feature evidence

Five new focused methods passed for explicit review/adoption, Cancel preserving
report bytes/revision, busy read/review rejection, invalid/directory/oversized/schema
errors, multiple/empty/remote inputs and bounded early-launch routing. Real app
built/launched; cold and warm Finder Open With reached saved report review. Warm
Cancel preserved the comparison; invalid and busy Launch Services requests retained
the active session/review. JSON remained an alternate viewer, with Nova observed
as the existing default. Cold post-review capture does not prove the intervening
adoption action; native multiple gestures and closed-window reopening are untested.
These receipts are reused for v0.1.11. Parser/type/generation/report checks reused;
no full suite. Accessibility remains stopped.
