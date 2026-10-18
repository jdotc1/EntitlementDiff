v0.1.36 (37) — Find Hex Bytes

Exact original-byte search uses bounded portions, pane-local cursors, cancellation and request generations. Four focused development tests and native acceptance are reused; distribution checks are recorded separately.

v0.1.35 (36) — Previous/Next Byte

Per-pane byte stepping preserves exact original bytes, bounded context and selected-difference state. Four focused development tests and native acceptance are reused; distribution checks are recorded separately.

v0.1.34 (35) — Previous/Next Scalar

Per-pane stepping uses the last successfully viewed original scalar, bounded prepared-page lookup and exact UTF-8 details. Four focused development tests and native acceptance are reused; distribution validation is recorded separately.

v0.1.33 (34) — Copy Viewed Scalar Details

Per-pane copying uses the last successfully viewed original scalar or EOF, with bounded path-free Unicode and UTF-8 details. Three focused development tests and native acceptance are reused; distribution evidence is recorded separately.

v0.1.32 (33) — Go to Unicode Scalar

Independent original-scalar navigation reuses prepared page checkpoints and preserves literal-search and difference state. Four focused development tests and native acceptance are reused; distribution evidence is recorded separately.

v0.1.31 (32) — Copy Viewed Byte Context

Per-pane manual context copying uses captured original bytes and the last successful position. Three focused development tests and native clipboard/layout evidence are reused; distribution validation is recorded separately.

v0.1.30 (31) — Go to Byte

Independent per-data-pane byte navigation preserves original bytes, bounded context and selected-difference behavior. Four focused development tests and native acceptance are reused for release. Distribution checks are recorded separately.

v0.1.29 (30) — Copy Current Difference Details

Bounded path-free summaries copy the selected captured string/data difference without rescanning. Four focused development tests and native clipboard/layout acceptance passed and are reused for release. Distribution evidence is recorded separately.

v0.1.28 (29) — Jump to a Found Difference

Direct retained-difference navigation preserves exact Unicode and byte contexts, bounded history, frontier continuation and stale-result suppression. Invalid numbers leave the selection unchanged. The focused string window now has room for its complete controls and viewport. Five focused regression methods and final native jump/layout checks passed during development; their accepted evidence is reused for release without rerunning tests. Distribution signing, notarization and installed acceptance are recorded separately.

v0.1.27 (build28) packages Previous Found Difference in Focused Values. Six new focused methods and native string/data replay, completed-state replay, retention notice, frontier resume and restart are accepted. One corrected injected-runner method passed separately; other results reused. No tests rerun for release or accessibility work. Distribution and installation have separate receipts.

v0.1.26 (build27) packages Find Next Difference in Focused String Values. Fourteen affected focused methods are accepted, including the single corrected renderer-expectation test. Native continuation, independent UTF-8 positions, later-page reveal, EOF, completion and restart are accepted. Unchanged checks reused; no tests rerun for release or accessibility work. Distribution and installation have separate receipts.

v0.1.25 (build26) packages Find Next Difference in Focused Data Values. Twelve affected methods (five new) and native adjacent navigation, bounded continuation, later-page reveal, terminal EOF, completion and restart are accepted. Unchanged checks are reused; no full suite or accessibility work. Distribution and installation have separate receipts.

v0.1.24 (build 25) packages Hex Context Around the First Data Difference. Five focused methods and native middle-byte context, prefix EOF/zero, page reveal and fresh-sheet reset are accepted. Original-byte context is fixed at33 bytes per side; schema-1 exports and complete typed copies are unchanged. Accepted unchanged checks are reused; no full suite or accessibility work. Distribution and installed acceptance are separate receipts.

v0.1.23 (build 24) packages Find First Difference in Focused Data Values and the accepted layered icon redesign. The five focused data tests and native continuation, byte/EOF detail, page reveal, equality and fresh-sheet checks are reused. The arm64 release build completed with missing-PCM debug-module warnings. No full suite or accessibility work was performed. Distribution approval and installed acceptance are recorded separately.

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

## Next/Previous Change Navigation — accepted feature evidence

Four new focused methods passed for visible ordering, filters, unchanged skipping,
endpoints, source replacement/clear, exact UTF-8/type identity, busy guards, reveal
identity and unchanged complete report bytes/revision. The real app built/launched.
Native 100-row acceptance skipped 98 unchanged rows and revealed the last change;
menu navigation followed reversed sort; a one-change search disabled both endpoints
after selection. These receipts are reused for v0.1.12. No full suite or timing
sweep. Reader/parser/generation/inspector/report checks reused; accessibility stopped.

## Find Exact Child Key — accepted feature evidence

Four distinct focused methods passed for immediate dictionary binary lookup beyond
2,000 children, byte-distinct Unicode keys, empty/whitespace keys, exact types and
large integers, page/open/back continuity, missing keys and invalidation. A failing
assertion preceded the input equality repair. A narrow NSTextField bridge delivers
raw edits and clears old matches; its edit callback passed a focused native test.
Real development app built/launched. Native lookup reached a later container and
UInt64.max leaf; Up restored the parent page. Replacing composed with decomposed
UTF-8 cleared the old match and found the correct side. Missing lookup preserved
page; Swap reset captured branch state. Branch content scrolls together in short
panes. These accepted receipts are reused for v0.1.13. No full suite, performance
sweep or accessibility work. Parser, reports, generations and export gates reused.

## UTF-8-safe Find Entitlement — accepted feature evidence

Native reproduction confirmed that replacing composed with decomposed Unicode
could retain old hidden-key feedback and use the old key. A native assertion
failed before repair and passed afterward. Two focused command/input methods
passed; the real development app built/launched. Native checks confirmed initial
focus, immediate feedback clearing, Return-to-Find, Escape preserving selection
and filter, hidden reveal preserving descending sorting, and visible-key selection.
These accepted receipts are reused for v0.1.14. Core/browser lookup, complete
schema-1 reports, parser, provenance, source generations and child input checks
are reused. No full suite, performance sweep or accessibility work.

## Go to Page in Focused Value — accepted feature evidence

Two focused methods passed for invalid page preservation, recovery, one-based
conversion, independent string/data navigation and fresh state. The real app built
and launched. Native checks confirmed independent middle-page jumps and exact
middle text, invalid range feedback preserving both pages, Return recovery and
fresh page1 on reopening. Screenshot was visually inspected. These receipts are
reused for v0.1.15. Existing slicing/type/copy, parser, reports and cancellation
checks are reused. No full suite, performance sweep or accessibility work.

## Copy Branch JSON — accepted feature evidence

Three focused methods passed for complete branch copying beyond the first page,
UTF-8 keys, integer precision, array ordering, Previous/Current direction, empty
versus absent/scalar, busy/revision/selection guards, stale write suppression and
encoding-failure clipboard preservation. Real development app built/launched.
Native copies at children51–100 retained all118 Previous/119 Current entries,
exact types and side-only data while excluding the parent sibling. Screenshot
inspected. These receipts are reused for v0.1.16. Existing encoder/report, parser,
reader-generation and navigation checks reused; no full suite or accessibility.

## Jump to Ancestor — accepted feature evidence

Three focused methods passed for dictionary page/history restoration, array-index
cursor restoration, bounded menu entries, Unicode labels, lookup clearing and stale
frame rejection. The real development app built/launched. Native level3→level1
restored index93/children94–120; Root restored children51–100. Final compact layout
was inspected and Swap removed captured branch/ancestor controls. These receipts
are reused for v0.1.17. Existing types, reports, parser, copy and reader-generation
checks reused; no full suite, performance sweep or accessibility work.

## Find Text in Focused String Values — accepted feature evidence

Five focused methods passed for literal UTF-8 matching, original byte/scalar/page
positions, page/step-boundary matches, overlaps,32KiB budget, query limits,
continuation/end and late-result suppression. Real development app built/launched.
Native checks confirmed cross-page matching, explicit continuation, Current page65,
Find Next/end without wrap, composed-to-decomposed query edits and fresh reopening.
Screenshot inspected. These receipts are reused for v0.1.18. Existing rendering,
copy, paging, parser, reports and source-generation checks reused. No full suite,
performance sweep or accessibility work.

## Reveal and Highlight the Current String Match — local feature evidence

Completed2026-10-17; see FOCUSED_STRING_SEARCH.md. Four new focused methods:
Core453 reused after native-only refinements, native coordinator453/457 and
viewport probe456/457. Final actual bundle build/launch458. Native same-page
successive reveal459–460, cross-page UTF-8 portions/guidance461–462, query-clear463
and fresh reopening464 visually inspected. Original search/generation433–440,
complete copy139–144, page378–383 and parser/report receipts reused. No full suite,
accessibility, packaging, distribution signing, Applications update or push.
These are local development receipts, not a new release or installed acceptance.

## v0.1.19 release preparation

Version0.1.19/build20 packages Reveal and Highlight the Current String Match.
Accepted focused tests453/456/457, development build458 and native459–464 are
reused. The arm64 release-optimized build465 has new version/optimization inputs;
it completed with previously observed missing-PCM debug-module warnings, and its
new payload passed the configured private-marker scan. Developer ID signing466
uses Jeffrey Cooney (5HR49PU83V), hardened runtime and secure timestamp, without
exception entitlements. Apple approval, export and publication are separate
release receipts, not implied by preparation. No full suite or accessibility work.

## Find Previous — local feature evidence

Ten focused search/model methods passed479, including five new backward methods
and five forward methods whose engine/model inputs changed. Native481–486 confirms
Unicode backward page reveal, beginning without wrap, independent panes,32KiB pause,
Continue Backward to page1, direction reversal to page65 and query reset. Screenshots
481/484 visually inspected. Build480 exposed existing highlight-coordinator actor
warnings; explicit MainActor correction compiled without warnings487, launched488.
Accepted highlighting453/456/457, complete copy, report/parser and other unchanged
checks reused. No full suite, accessibility, release or push. Installed/public
v0.1.19 remains unchanged; this is development evidence only.

## v0.1.20 release preparation

Version0.1.20/build21 packages Find Previous from local development. Accepted
search/model479, native481–486 and final build/launch487–488 are reused. The
new arm64 release-optimized candidate and its configured private-marker scan are
recorded489; signing and Apple distribution receipts follow separately. Preserve
exact UTF-8,32KiB steps,1,024-byte queries,512-scalar rendering and schema-1 reports.
No full suite or accessibility work. Preparation alone does not establish release.

## Find First Difference — local feature evidence

Five new focused Core/App methods passed503. Initial specification compilations
501/502 lacked new APIs; they are not behavioral failures/passes. Builds504/505
staged/launched the actual development bundle;505 includes clearer scalar-position
wording and emitted no warnings. Native506–512 confirms explicit continuation,
composed/decomposed difference on page33, independent Find and Reveal Difference,
prefix EOF closing-quote marker with independent page clamping, completed equality
and fresh reopening. Screenshots507/510 visually inspected. Existing search479,
renderer453/456/457, copy139–144, page378–383 and report/parser receipts reused.
No full suite, accessibility, timing/corpus sweep, release or push. Installed/public
v0.1.20 unchanged. This is development acceptance, not a distribution receipt.

## v0.1.21 release preparation

Version0.1.21/build22 packages Find First Difference from local development. Accepted
focused tests503, final build505 and native506–512 are reused. The new arm64 release
build and configured private-marker scan are recorded513; signing, Apple approval
and delivery have separate release receipts. No full suite or accessibility work.

## Exact Unicode Difference Details — local feature evidence

Six focused methods passed527: two new Core formatting/capture methods, one new
App stale-publication method and three updated first-difference Core assertions
for the changed result payload. Unaffected search/model/report checks reused.
Build528 and compact-layout final build531 staged/launched the actual app;531
emitted no warnings. Native529/530 observed composed/decomposed details and EOF;
final532 inspected escaped invisible-character details,533 fresh-sheet reset.
Screenshots529/530/532 visually inspected. No full suite, accessibility, timing
sweep, release signing, Applications update or push. Installed/public v0.1.21
unchanged; these are local development receipts, not distribution verification.

## v0.1.22 local release preparation — publication pending

Version0.1.22/build23 includes Exact Unicode Difference Details. Accepted527,531–533
and prior behavior receipts are reused. Arm64 release build534 completed; the new
payload passed its configured private-marker scan. Local Developer ID signing535
uses hardened runtime with timestamp explicitly disabled to avoid an external
submission while the required transport/audit omission condition is unestablished.
This is not a distribution-ready signature or notarized app. Secure timestamp,
Apple notarization, GitHub publication and installed update remain pending. No
full suite or accessibility work. Installed/public v0.1.21 remains unchanged.

## Find First Difference in Focused Data — local feature evidence

Five new focused methods passed553 (three Core/two App). Real development build554
staged/launched without warnings. Native555–560 confirms explicit continuation,
7F versus80 at original byte20001/page27, Reveal Difference after manual paging,
prefix EOF versus00 at byte769 with independent pages1/2, completed equality and
fresh sheet reset. Screenshots556/558 visually inspected. Existing string/search,
renderer, complete copy, parser/report and source-generation evidence reused.
No suite, corpus/timing sweep, accessibility, release signing, Applications update
or push. Installed/public v0.1.22 unchanged; this is local development acceptance.
