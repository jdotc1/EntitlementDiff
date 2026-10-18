Direct one-based page navigation added locally2026-10-17; see LEAF_PAGE_JUMP.md. Existing rendering/copy/preparation evidence below is reused.

# Focused value viewer and typed leaf copy

Implemented locally 2026-10-15 on milestone 2 local development. This is the
explicitly authorized milestone 3 scope: long-value viewing and exact scalar copy.
All Keys and deeper-tree navigation remain separate future work.

## Behavior and implementation

Each inspected row with a scalar on either side offers **View Value…**. The sheet
captures Previous and Current values when opened, labels their types, and supplies
independent First/Previous/Next/Last controls. Strings use 512 Unicode scalars per
page, slicing before display escaping; data uses 768 bytes per page rendered as
base64. Empty strings/data have one page. Scalar boundaries preserve original text
bytes when reconstructed; a combining sequence may span pages. This is a text
inspection view, not an editor. Existing tree traversal/preview limits remain.

String-page indexing runs in a cancellable detached task. Rendering reads only the
chosen page (at most 4,098 escaped scalars for strings, 1,024 base64 characters for
data). The page index still grows with total string length; this is not a constant
memory or benchmark claim. Each presentation has a fresh UUID, preventing a later
selection from retaining old document/page state. Dismissal cancels preparation
and a cancellation check prevents late publication.

**Copy Previous/Current Leaf JSON** encodes the complete captured side with the
existing tagged `EntitlementValue` encoder, off MainActor. It preserves the exact
integer strings and Boolean/string/data/date/real tags. No key/path wrapper is
added. Current page and display escaping never define the payload. Absent sides
and containers cannot be copied as leaves; their context remains visible. The
existing whole-entitlement **Copy Selected JSON** action remains available.

Source/report actions are blocked while the sheet is open. Concurrent copy and
sheet dismissal are disabled while encoding/copying. An encoding failure reports
an inline error, restores controls and leaves the clipboard untouched. A native
clipboard rejection is reported separately after attempting the write. No history,
files, source mutations, schema changes, new dependency or inspection scope added.

## Executed validation and reused evidence

1. `swift test --filter 'InspectorLeafTests|LeafCopyActionTests' -Xswiftc -warnings-as-errors`
   in `evidence/139-leaf-viewer-focused-tests.log`: seven new methods compiled and
   ran; six passed. One signed-zero assertion failed because the test parsed JSON
   through `JSONSerialization`/`NSNumber`, which inferred an integer zero. The
   test oracle was corrected to decode the tagged real as `Double`. Production
   encoding was unchanged; this is not a production red/green defect claim.
2. `swift test --filter InspectorLeafTests/testTypedScalarsAndEmptyLeavesDoNotBecomeContainersOrAbsent -Xswiftc -warnings-as-errors`
   in `evidence/140-leaf-signed-zero-typed-decode.log`: only that changed method
   reran and passed. Reuse the other six passes from 139: seven distinct passing
   methods total. Coverage includes suffix reachability, scalar/UTF-8 fidelity,
   escaped controls, sliced data/base64, exact integer extremes, signed zero,
   empty-versus-absent/container, captured side copy, concurrent-copy refusal,
   encoding failure recovery and private pasteboard contents.
3. `./script/build_and_run.sh` in `evidence/141-leaf-viewer-native-build.log` built
   and launched the real staged development bundle. Its usual ad-hoc signature is
   a build step, not Developer ID/signature verification or distribution proof.
4. Native Computer Use opened the long-text leaf, inspected both third-page
   differing suffixes and copied Current from page 3. The newly produced clipboard
   decoded to the exact original 1,331-character typed string (142). Dismissal and
   a different selection showed fresh Page 1 of 1, the complete UInt64 maximum and
   disabled absent-side copy. Screenshot inspected for the new sheet; native
   observations and staged executable identity are recorded in 143.
5. `/usr/bin/log show --last 8m --style compact --predicate 'process == "EntitlementDiff"'`
   captured 144. It contains previous/current-process system-service messages and
   AppKit geometry faults. The historical sharing-indicator diagnosis remains
   context only; no new stack attribution was performed. No crash or hang was
   observed during these interactions. This is not a fault-free-runtime claim.

A separate read-only in-thread reviewer inspected the final implementation and
found no consequential source defect. Its signed-zero test-oracle concern was
resolved by 140. It performed no checks or mutations. The scoped review covered
paging/cancellation, identity, scalar eligibility, captured copy, busy guards and
macOS availability; it is not a security certification.

Accepted baseline 32, inspector/navigation 54–63, report/schema and browser
133–138 remain reused for unchanged boundaries. No full `verify.sh` suite, eight
native extraction methods, unchanged signing/dependency/hash check or corpus run
was repeated. No performance benchmark, minimum-macOS-14/Intel acceptance,
accessibility work, install, notarization, release packaging or push. Published
and installed v0.1.2 remain separate; no new distribution claim.

## Find First Difference in Focused Data Values — 2026-10-17

When both captured values are data, Find First Difference begins at the original
bytes. Continue Comparison explicitly examines another bounded portion; partial
agreement never becomes a No difference result. A mismatch reports its original
one-based byte position and each side's uppercase hexadecimal byte. End of data
is explicit and distinct from00. Empty/equal values remain valid. Mixed, absent
or non-data pairs do not receive this data action; string comparison/search keep
their existing workflow. This locates the first byte difference, not an aligned
binary diff or a decoded format comparison.

DataFirstDifference retains immutable Data values, native Data indices and a
relative byte offset, including Data slices whose startIndex is not zero. It does
not flatten full byte arrays, decode/re-encode base64, compare display text or
rescan a prefix for each continuation. Steps read at most32,768 original bytes
across both inputs combined, reserving two bytes per pair; smaller test budgets
have a two-byte minimum. Cancellation is checked at entry/every256 pairs. Storage
and the captured value size remain separate from this per-action work budget;
no constant-memory or elapsed-time claim is made.

FocusedDataDifference owns a separate MainActor session and cancellable detached
steps. A request generation as well as cancellation guards every publication.
Restart/dismissal invalidates cursor, result and work. Existing captured selection
identity creates fresh state. A result arriving before leaf preparation is applied
when its document becomes ready. Original byte offset maps to the existing768-byte
base64 page; each side independently clamps an EOF boundary to its last page.
Reveal Difference only changes presentation revision and restores/reset-scrolls
those pages. Manual paging remains available. Base64 characters are not highlighted
as individual original bytes. Exact byte/EOF details identify the saved difference.
No new encoding, report schema, saved provenance or clipboard contract is introduced;
Copy Leaf JSON still contains the complete tagged original value.

Evidence:

- 552: specification compilation before the new APIs existed. Missing-symbol
 failure is not a behavioral regression failure or a passing test.
- 553: `swift test --filter 'DataFirstDifferenceTests|FocusedDataDifferenceTests' -Xswiftc -warnings-as-errors`
 passed five new methods (three Core/two App), covering later-page7F/80 identity,
32KiB combined cap, explicit small-budget continuation, equality only after all
bytes, empty/prefix EOF versus00, nonzero-index Data slices, independent restart/
reveal state, terminal guards and a deliberately computed byte result returning
after cancellation. No pre-existing behavioral defect was confirmed.
- 554: `./script/build_and_run.sh` built/staged/launched the actual development
bundle without warnings. Ad-hoc development signing is not distribution proof.
- 555: synthetic data pair paused with explicit Continue Comparison and no result.
- 556: continuation found original byte20001, Previous7F/Current80, and navigated
both panes to page27 of27. Existing base64 display remained unhighlighted;
screenshot visually inspected.
- 557: manual Previous First page followed by Reveal Difference restored page27
without starting comparison again.
- 558: Previous ended after768 bytes while Current continued with00. The summary
reported byte769; Previous clamped to page1/1 and Current opened page2/2. No false
zero byte was assigned to EOF. Screenshot visually inspected.
- 559: equal original data completed with explicit No difference.
- 560: Done/reopen cleared saved data comparison and detail state. App open.

Accepted string comparison503, Unicode metadata527/531–533, search479, scalar
renderer453/456/457, full leaf copying139–144, page378–383 and parser/report/
source-generation checks reused for unchanged boundaries. Only the five new data
methods ran. No suite, corpus/timing sweep, unchanged hashes/signatures,
accessibility, broad appearance work, packaging, release, Applications update or
push. Installed/public v0.1.22 unchanged; unrelated audit preserved.

## Hex Context Around the First Data Difference — 2026-10-17

After a data comparison finds its first difference, both panes show a compact
original-byte hex window. Up to16 bytes precede the bracketed target and up to16
follow it. Range and target labels use one-based original byte positions. EOF
is [EOF], distinct from [00]; empty data has no invented surrounding bytes.
Windows clamp to each value independently. Existing base64 pages, Reveal Difference
and complete Copy Leaf JSON remain available and retain their contracts.

DataDifferenceContext uses native Data indices relative to startIndex, supporting
sliced Data without flattening or decoding. Initialization rejects invalid offsets
before indexing. It reads/formats at most33 bytes per side once, under the same
MainActor cancellation/generation publication guard as the saved difference.
This fixed work adds no additional comparison step or asynchronous publication.
Stored context is cleared on restart/dismissal, unchanged by manual paging/reveal,
and rendered by a narrow SwiftUI section with no full-source formatting in body.
The existing32KiB comparison-step bound is unchanged; the fixed66-byte maximum
context preparation is separate. No constant-time whole-comparison claim is made.

New evidence:

-575: `swift test --filter 'DataDifferenceContextTests|FocusedDataDifferenceTests.testHexContextPublishesWithResultAndClearsOnRestart|FocusedDataDifferenceTests.testCancelledResultCannotPublishHexContext' -Xswiftc -warnings-as-errors`
 passed five new methods (three Core/two App). Covers exact surrounding bytes,
33-byte cap, beginning/last/empty/prefix EOF versus00, sliced storage, invalid
offsets, saved reveal identity, restart clearing and computed-result cancellation.
No pre-existing behavioral defect was confirmed; specifications preceded new APIs.
-576: `./script/build_and_run.sh` built/staged/launched the real development app
without compiler warnings. Native process uses this checkout's dist bundle.
-577: synthetic64-byte pair differed at byte33 (20 versusFF); each pane showed
bytes17–49, exact preceding10–1F, bracketed target and following21–30. Native
screenshot visually inspected; context/layout/base64 and copy controls fit.
-578: Previous768FF versus Current768FF+00; context shows bytes753–768 [EOF]
versus bytes753–769 [00], and existing base64 pages independently reveal1/1 and2/2.
Screenshot visually inspected; no fabricated byte or page-alignment highlight.
-579: manually navigating Current to page1 retained the saved context; Reveal
Difference restored page2 without another comparison or context generation.
-580: Done/reopen returned to ready with no difference/context and original pages.

Fixture: dist/data-hex-context-acceptance/HexContext.json, synthetic schema-1 pair;
no inspected executable launched. Prior data553/555–560, string/search,
renderer453/456/457, full leaf copy139–144, page378–383 and parser/report evidence
reused for unchanged boundaries. No full suite, accessibility, timing/corpus sweep,
unchanged hash/signature check, release or push. Installed/public v0.1.23 remains
unchanged. This is local development acceptance, not distribution qualification.

## Find Next Difference in Focused Data Values — 2026-10-17

After finding a mismatch, Find Next Difference starts immediately after the saved
original-byte position. Adjacent unequal bytes are separate results. Long equal
intervals still require explicit Continue Comparison after a32KiB combined input
step. While paused, the prior byte/EOF details and hex context remain available
and Reveal Difference still points to that saved result. A new result updates
ordinal, context and existing base64-page reveal together. Base64 remains display,
not comparison input. Prefix EOF is one terminal result; there is no suffix walk,
wrap, alignment heuristic or invented byte. Completion says No further differences
rather than falsely claiming the original pair equal. Restart returns to first.

DataFirstDifference.movePastDifference explicitly advances past an already-read
mismatch in constant work. Native indices and relative offsets handle sliced Data.
EOF marks exhaustion without visiting the unmatched suffix. The existing step API
still returns the saved mismatch unless explicitly advanced. FocusedDataDifference
starts next work under a new request generation; its existing cancellation and
generation guard prevents a late next result replacing a restarted first result.
Context formatting remains fixed at33 original bytes per side and occurs only on
new accepted results. Manual page/reveal and complete copies remain independent.

Evidence:
-594: `swift test --filter 'DataFirstDifferenceTests|FocusedDataDifferenceTests' -Xswiftc -warnings-as-errors`
 passed12 affected methods: five Core/seven App, including five new methods.
New coverage includes adjacent mismatches, one terminal EOF, sliced values,
bounded long equal intervals, next context/ordinal, completion guards, restart,
retained context during pause, and a computed next result returning after a newer
first request. Seven prior methods were affected by cursor/session changes;
unmodified context formatter575 and unrelated checks were reused. No pre-existing
behavioral defect was confirmed; this adds explicit forward navigation.
-595: `./script/build_and_run.sh` built/staged/launched without compiler warnings.
-596: native next advanced first byte00/7F to adjacent byte2 00/80, updated ordinal/context.
-597: next paused across the equal interval, retained byte2 context and disabled Next;
Continue Comparison remained explicit. No false completion/equality.
-598: continued to difference3 at byte20002,00/FF, both page27; exact context updated.
Screenshot visually inspected, layout and existing copy/base64 controls fit.
-599: next returned difference4 at byte20003, EOF versus00, once.
-600: following next reported No further differences, disabled Next, kept last
context and Reveal Difference. Screenshot visually inspected.
-601: Find First Difference reset ordinal, result/context and both pages to byte1/page1.

Fixture: dist/data-next-difference-acceptance/NextDifference.json, synthetic schema-1
captured pair with adjacent/distant/terminal changes. Inspected executables were
not launched. Accepted context575/577–580, unchanged string/search, complete
copy139–144, page378–383 and parser/report evidence reused. No suite, accessibility,
performance sweep, distribution action or push. Installed/public v0.1.24 unchanged.

## Previous Found Difference in Focused Values — 2026-10-17

Previous Found Difference revisits discovered results in both string/data focused
sheets. Find Next Difference replays retained results before resuming the single
frontier cursor. It is discovered-result navigation, not a reverse source search.
A fixed64-entry history stores only immutable positions and ordinals, not source
copies or a cursor per entry. Eviction exposes "Found history starts at difference
N. Find First Difference to restart." The oldest retained result disables Previous;
there is no wrap. Restart/dismissal clears history and completion state.

Replay restores exact byte/scalar/EOF details, per-side UTF-8 coordinates and reveal
revision. Data context is regenerated within the accepted33-byte-per-side bound;
string highlights reuse per-side mapping. Comparison runners are not called for
replay. The cursor stays at the furthest discovered result. Completed-state replay
returns to finished at the frontier without a new scan. While running/paused,
Previous/Next are disabled; continuation retains the last result. Generation and
cancellation guards prevent a stale result populating restarted history. Existing
32KiB scan steps, rendering, literal search, copy and schema-1 reports remain.

Evidence:
-635: `swift test --filter FoundDifferenceHistoryTests -Xswiftc -warnings-as-errors`
 ran six new methods. Five passed; one test runner constructed a tuple containing
the pre-step cursor before evaluating its mutating step. Production runner already
computes step before return; this was a test helper error, not an app defect.
-636: corrected only that runner evaluation order; `swift test --filter 'FoundDifferenceHistoryTests.testDataReplayDoesNotRunComparisonAndResumesFrontier' -Xswiftc -warnings-as-errors`
 passed. Other five results635 reused. Coverage includes64-entry eviction, exact
ordinals, replay without runner calls, frontier resumption, completed/EOF replay,
independent UTF-8 details, both model history caps/reset, and late computed data/
string results arriving after restart. Only new methods ran, no existing suite.
-637: `./script/build_and_run.sh` built/staged/launched the real development app.
-638: native string Previous restored result1 after discovering result2.
-639: Next replayed result2 with Previous byte2/Current byte5, U+00E9/C3 A9 and
U+200B/E2 80 8B. Original highlight/details restored; screenshot visually inspected.
-640: completed string scan, Previous restored result3; Next restored terminal EOF
and finished state with Next disabled, without wrap or another scan.
-641: native data traversal reached difference65; notice states retained history
starts at difference2. Controls, context and notice fit; screenshot inspected.
A transient computer-use capture failure interrupted at result20; current state
was read and navigation resumed without restart or duplicate actions.
-642: Previous restored data result64/context, Next replayed65, then resumed to66;
retention notice advanced to3. Tests636 prove replay does not call runner.
-643: restart returned to result1, disabled Previous and cleared retention notice.

Synthetic schema-1 fixture: dist/found-history-acceptance/History.json,72 unequal
data bytes plus a Unicode pair. No inspected executable launched. Previous Core
comparison/data/Unicode checks594/614/615, fixed context575, renderer453/456/457,
complete copy139–144, page378–383 and parser/report receipts reused. No suite rerun,
accessibility, performance sweep, unchanged hashes/signatures, release or push.
Installed/public v0.1.26 unchanged; this is development acceptance only.

## Jump to a Found Difference — 2026-10-17

Both string/data sheets offer Go to found difference with Go and Return. The
visible Found differences A–B is the retained discovered range, not a total count.
A valid ordinal directly restores its captured result, exact UTF-8/byte metadata,
page reveal/highlight and fixed data context. No comparison scan is triggered.
Next replays remaining records before resuming the frontier. Completed-frontier
jumps restore finished, while older records remain navigable. History stays64.

Parsing reads at most21 UTF-8 bytes before validation, accepts1–20 ASCII digits,
rejects overflow and bounds to retained ordinals. Field input is bounded to a
21-byte UTF-8 prefix with safe decoding. Signs, whitespace, non-ASCII digits,
zero, future and discarded ordinals are invalid. Failure shows the valid range
without changing the current position/revision. Existing eviction guidance explains
how to restart for older results. Successful jump uses a fresh generation and
cancellation; running/paused work rejects navigation. Restart clears input/error
and history. Existing value fidelity, comparison/render budgets, copies and reports
are unchanged.

Evidence:
-656: `swift test --filter FoundDifferenceJumpTests -Xswiftc -warnings-as-errors`
 passed five new methods. Covers strict/bounded parsing and overflow, evicted range
7–70, first/middle/last direct selection, invalid nonmutation, both session caps,
exact independent UTF-8 offsets, data context/EOF, finished-frontier restoration,
runner-call count proving no jump scan, next frontier resumption, reset and late
computed publication after restart. Existing accepted tests were not rerun.
-657/658: initial real build and native string jump passed coordinate/detail checks
but showed a clipped string viewport after adding the new row. Screenshot658 is
pre-fix evidence, not accepted final appearance.
-659: failing native regression UI-JUMP-01 recorded before the layout fix, with
fixture/actions/expected readable text and observed clipping. No compiler-only
claim or fabricated automated geometry assertion. The fix increases the sheet
from560 to680 points and guarantees an80-point minimum string viewport.
-660: `./script/build_and_run.sh` built/staged/launched final app without warnings.
No model tests repeated after this view-only layout change;656 remains applicable.
-661: final native jump3→2 restores Previous byte2/Current byte5, exact Unicode
details and highlight; readable original text, page/search/copy controls fit.
Screenshot inspected. UI-JUMP-01 passes on corrected layout.
-662: future4 rejected while retained1–3; result2 and coordinates unchanged.
Guidance and readable viewport fit together; screenshot inspected.
-663: Return jumped to3, Next resumed to EOF/finished; jumps2→4 restored finished
without a scan, Next disabled at completed frontier.
-664: data jump4→2 restored original00/01 and bounded hex context. Screenshot inspected.
-665: Return selected data1; invalid5 left result1, then restart cleared error and
reset found range to1–1 with Previous disabled.

Fixture reused: dist/found-history-acceptance/History.json. Existing64-entry history
635/636 and boundary641, comparison594/614/615, fixed context575, renderer453/456/457,
copy139–144, page378–383 and parser/report receipts reused for unchanged boundaries.
No suite rerun, accessibility, broad appearance campaign, timing/corpus sweep,
unchanged hashes/signatures, release or push. Current ambient dark appearance was
observed without changing system settings. Installed/public v0.1.27 unchanged.

Copy Difference Details uses the current captured string/data mismatch with
exact scalar/UTF-8 or byte/EOF details and bounded context. No rescans or source
paths; clipboard output is limited to2048 UTF-8 bytes and guarded by focused
selection identity. See COPY_DIFFERENCE_DETAILS.md for scope and evidence678–684.

Go to Byte offers independent per-data-pane1-based decimal navigation to an
original byte or EOF, with bounded33-byte hex context and direct base64 page
selection. Manual viewing does not change the selected difference or its copied
details. Reveal Difference resets manual navigation. Strict bounded input, invalid
nonmutation and dismissal reset are covered in GO_TO_BYTE.md, evidence697–703.

Copy Byte Context copies the last successfully viewed manual byte/EOF context
for an explicit side, independently of pending/rejected field text and selected
difference. Original hex bytes and positions remain bounded/path-free; clipboard
output limit1024 UTF-8 bytes and focused-selection UUID guard apply. Reveal
Difference clears manual copy actions. See COPY_VIEWED_BYTE_CONTEXT.md,716–723.

Go to Unicode Scalar provides independent1-based original-scalar/EOF navigation
with exact code points and UTF-8 positions/bytes. Prepared page checkpoints bound
lookup to512 scalars; no prefix rescan. Manual display preserves difference/search
sessions, and Reveal Difference or new search restores its corresponding display.
Strict bounded input and exact-state/native evidence736–745: see GO_TO_SCALAR.md.

Copy Scalar Details uses a pane’s last successful manual scalar/EOF and exact
UTF-8 position/bytes, independently of pending/rejected text. Output is path-free
and capped1024 UTF-8 bytes, with focused-selection UUID clipboard guard. Search/
reveal resets remove manual actions. See COPY_VIEWED_SCALAR_DETAILS.md,758–766.

Previous Scalar and Next Scalar move from the last successfully viewed original
scalar through bounded prepared-page lookup, updating highlight/UTF-8 details/copy
together. First/EOF stop without wrap; pending input and search/difference state
remain independent. See SCALAR_STEPPING.md for evidence779–790.

Previous Byte and Next Byte step from the last successfully viewed original
byte/EOF, updating fixed hex context, base64 page and copied context together.
First/EOF stop without wrap. Pending/rejected input and selected-difference state
remain independent. See BYTE_STEPPING.md for evidence803–813.

Pane-local hex search reads original data with a retained KMP cursor, bounded
32768-byte portions and128-byte patterns; generation/cancellation guards reject
stale results. Exact range and bounded hex preview accompany page reveal,
independent of manual navigation and comparison history. See HEX_BYTE_SEARCH.md.
