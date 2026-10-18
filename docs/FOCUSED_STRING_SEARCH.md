# Find Text in Focused String Values

Completed locally 2026-10-17 against a local development revision / released v0.1.17.
Each captured string pane has independent literal-text Find and Find Next controls.
Find starts at the beginning; Return in the query field also starts Find. Find Next
continues without wrapping, including overlapping matches. At an exhausted step
budget, Continue Search explicitly examines the next portion. No search runs on
every keystroke. Data/base64 and non-string search are outside this milestone.

Queries match exact UTF-8 bytes, including case, spaces and composed/decomposed
Unicode spellings. Valid queries contain1…1,024 UTF-8 bytes; empty/over-limit input
gets guidance. The shared native ExactKeyField preserves raw edits and immediately
invalidates old query results. Each side is identified by its Existing Previous/
Current pane rather than introducing a shared side selector.

## Work and fidelity boundary

StringValueSearch uses incremental KMP over the original immutable String.UTF8View.
It does not materialize the complete source byte array. Each explicit step consumes
at most32,768 source bytes; smaller test budgets cannot raise this ceiling. Pattern,
prefix table and scalar-position ring are bounded by1,024 query bytes. Matching
state carries across step/page boundaries, including a split multibyte scalar.
Original byte/scalar offsets map the match's beginning to the existing512-scalar
page. Byte positions and pages are displayed one-based; no parsed/escaped preview
is searched. Valid UTF-8 patterns begin at scalar boundaries. Display escaping,
complete leaf copying and768-byte data pages are unchanged. Source/String storage
and existing page indexing are proportional to the captured value; this is not a
whole-app constant-memory or elapsed-time claim.

FocusedStringSearch owns per-pane query/session state on MainActor. Steps run in
cancellable detached tasks and check cancellation periodically. Request generations
as well as cancellation guard publication. Query edits, restart and dismissal
invalidate the generation/cursor/results. Fresh value sheets have fresh state.
Find can restart a running request; advance is refused while running or at end.
A matched result navigates only its side to the beginning page. It does not render
or highlight the entire match, which may span multiple pages. Paging remains
available independently, and full Copy Leaf JSON retains its captured original.

## New focused evidence

`swift test --filter 'StringValueSearchTests|FocusedStringSearchTests' -Xswiftc -warnings-as-errors`
passed five new methods433 (three Core, two App). Coverage includes page-boundary
and32KiB-boundary matching, split UTF-8 bytes, exact Unicode/case/space semantics,
overlapping matches, original offsets/page mapping, query bounds, empty source,
explicit continuation/end state, invalid query, independent per-session state,
and a deliberately late computed result after query cancellation. A dismissal
cancel also leaves results unpublished. No behavioral defect was confirmed.

`./script/build_and_run.sh` built/staged/launched the actual Swift6/macOS14+ native
development app434. Ad-hoc staging signature is not distribution verification.
A small synthetic saved pair has a three-page Previous string and65-page Current:

- Previous query🙂target crosses a rendering page boundary; match begins at original
  byte1023/page1, despite multibyte é prefix435.
- Current target first paused after32KiB with explicit Continue and no false end436.
  Continue found byte32769 and navigated only Current to page65; screenshot437
  visually inspected. Previous remained page1.
- Find Next found the second occurrence at byte32776, then reached explicit end and
  disabled Find Next without wrapping438.
- Replacing composed é by decomposed e+accent cleared previous feedback and found
  only the decomposed bytes at byte1636/page3 through actual native edits439.
- Done/reopen reset both queries/results and both pages440. Development app open.

Accepted native text field359/361–365, leaf slicing/copy139–144, page378–383,
parser/report, source generations and distribution421–432 reused for unchanged
boundaries. No full suite, corpus/timing sweep, unchanged hash/signature check,
accessibility or broad appearance work, Applications update, packaging, release
or push. Installed/published v0.1.17 unchanged; historical audit preserved.

## Reveal and Highlight the Current String Match — 2026-10-17

This follow-up supersedes the original no-highlight limitation above. Each current
match is highlighted only where it intersects the selected512-scalar page. Find
and Find Next reveal its beginning, including a later occurrence on the same page.
A page containing a continuation also reveals its visible portion. Guidance states
whether the match continues from/to neighboring pages. Ordinary paging remains
independent. Editing one query clears that side's old styling and pending reveal;
Done/reopen resets both pages and queries.

LeafValueDocument adds original UTF-8 page-start offsets during existing cancellable
off-main indexing. stringPage maps scalar spans into escaped display UTF-16 ranges
while visiting only the requested page. Wrapping quotes are excluded; escaped
controls, quotes, backslashes and surrogate pairs retain correct highlight ranges.
No normalization or source replacement occurs. Storage remains proportional to
existing captured values/pages; no whole-app constant-memory claim is made.

HighlightedStringPageView is a narrow NSViewRepresentable around a read-only,
selectable NSTextView. Only bounded escaped text enters AppKit. Character wrapping
keeps the page within the viewport. Semantic selected-text background/foreground
colors provide paired contrast. Styling does not set the user's text selection,
steal query focus, modify copied values or alter schema-1 exports. New page/match
revisions queue one reveal after layout; query clear and teardown drop pending
work. Existing detached search cancellation plus generations are unchanged.

New evidence (four distinct methods; no full suite):

- 453: `swift test --filter 'StringPageHighlightTests|StringMatchRevealTests' -Xswiftc -warnings-as-errors`
 passed two Core mapping/bounds methods and the initial native coordinator method.
 Includes byte-exact escaped text, composed/decomposed Unicode, emoji, controls,
 quotes/backslashes, cross-page portions and clearing.
- 456: `swift test --filter StringMatchRevealTests/testNativeViewportDoesNotScrollHorizontallyToRevealMatch -Xswiftc -warnings-as-errors`
 passed the added viewport probe. It did not reproduce a horizontal-scroll defect;
 this is coverage, not a failed-then-fixed regression claim.
- 457: `swift test --filter StringMatchRevealTests -Xswiftc -warnings-as-errors`
 passed both App methods after paired semantic colors/character wrapping refinement.
 Repetition was limited to changed native renderer inputs; Core453 reused.
- 454 initial and458 final `./script/build_and_run.sh` built/staged/launched the real
 Swift6/macOS14+ development bundle. Ad-hoc development signing is not distribution
 validation.455 captures the initial highlight; its contrast motivated the paired
 semantic-color refinement rather than a separate appearance campaign.
- 459/460: native Find/Find Next revealed Current byte401 then467 on page1, moving
 the highlight to the second occurrence. Both screenshots visually inspected.
- 461/462: Previous 🙂target began at original byte1023/page1 after511 multibyte é;
 emoji highlighted at the visible end, then target highlighted on page2 with
 matching forward/back continuation guidance. Screenshots visually inspected.
- 463: actual native query replacement cleared Previous highlighting and guidance
 while Current retained its own match.464: Done/reopen reset both pages/queries,
 highlights and scroll position. Screenshots visually inspected.

Search engine and late-result suppression433–440, raw field359/361–365, complete
leaf copy139–144, page378–383 and unchanged parser/report evidence reused. No full
suite, timing/corpus sweep, unchanged signature/hash checks, accessibility or broad
appearance work, packaging, publication or Applications update. Installed/public
v0.1.18 is unchanged. No confirmed pre-existing behavioral defect was found in
this milestone. The development app remains open with the synthetic fixture.

## Find Previous in Focused String Values — 2026-10-17

Completed locally against a local development revision / released v0.1.19. This follow-up adds
Find Previous to each string pane. It is unavailable before a match exists; Find
still restarts forward from the beginning. Find Next/Previous exclude the current
match start but retain overlaps. Neither direction wraps. The beginning message
keeps the last match visible and disables backward continuation; Find Next can
change direction from there. A backward step that finds no match in32,768 bytes
shows Continue Backward. Opposite-direction navigation restarts from the last
visible match, not the partially searched position. No match history is accumulated.

The immutable source remains shared by cursor values. The cursor retains an index
at its last match plus original byte/scalar offsets. Switching direction adjusts
that index by at most the1,024-byte query length and rebuilds a bounded KMP prefix
table for the reversed pattern. Reverse scanning decrements original UTF-8/scalar
positions and carries partial-pattern state across explicit steps, even mid-scalar.
Forward switching starts one byte beyond the last start, retaining overlaps without
normalizing text. No whole-source byte array or restart-from-beginning scan is used.
The32KiB ceiling counts source bytes per step; query preprocessing/anchor movement
is additionally bounded by1,024 bytes. Existing source/page indexing storage remains
proportional to the captured value; this is not a constant-memory or timing claim.

The MainActor model cancels old work and replaces its generation on direction
switch, query edit, restart or dismissal. Detached work periodically checks
cancellation; publication additionally requires matching generation. Each pane owns
its direction/session. Opposite-direction actions can supersede pending work when
a prior match exists. Highlight/reveal use existing match revisions and byte ranges.
Rendering, typed copying, parser/provenance and path-free schema-1 exports unchanged.

Evidence:

- 477 Core and478 model specification compilations demonstrate the initially missing
 API, not a behavioral failure or regression pass. No pre-existing behavioral defect
 was confirmed in this milestone.
- 479 `swift test --filter 'StringBackwardSearchTests|FocusedBackwardSearchTests|StringValueSearchTests|FocusedStringSearchTests' -Xswiftc -warnings-as-errors`
 passed ten methods: five new and five existing forward methods with changed
 engine/model inputs. New cases cover overlaps/direction reversals/endpoints,
 multibyte/page and32KiB boundaries with2-byte continuation steps, composed versus
 decomposed identity, no-match initialization guard, model beginning/query reset,
 backward pause and deliberately late backward output after switching forward.
- 480 `./script/build_and_run.sh` built/staged/launched the actual development app.
 It exposed pre-existing actor-isolation warnings in the highlight coordinator.
 The coordinator now has explicit MainActor isolation;487 rebuilt without warnings,
 and488 records the final native main window. This compiler correction is not a
 failed-then-fixed behavioral test. No new API or appearance campaign was needed.
- 481: Previous 🙂target found later byte1074/page2, then Find Previous returned to
 original byte1023/page1, highlighted the emoji and showed cross-page continuation.
- 482: another backward action reached explicit beginning without wrapping; forward
 remained available. Current's independent query still began at byte1/page1.
- 483: Current reached its later match at byte32776/page65; Find Previous paused at
 the byte ceiling with Continue Backward, retaining its match/page until found.
- 484: Continue Backward found byte1/page1; Previous retained its match/page.
 Screenshots481/484 were visually inspected.
- 485: switching forward from that match paused/continued to byte32776/page65 again.
- 486: native Current query replacement cleared match feedback and disabled both
 navigation directions while Previous retained its independent state.

Accepted renderer mapping/coordinator453/456/457 and native459–464 are reused for
unchanged rendering behavior. Complete leaf copy139–144, page378–383, raw text field,
parser/report and other unaffected receipts reused. No full suite, corpus/timing
sweep, unchanged signature/hash checks, accessibility, broad appearance work,
Applications update, packaging, release or push. Installed/public v0.1.19 unchanged.

## Find First Difference in Focused String Values — 2026-10-17

Completed locally against a local development revision / released v0.1.20. When both captured
sides are strings, Find First Difference explicitly begins at the start. At a
step boundary, Continue Comparison examines the next portion. No comparison runs
on query edits or every view update. Completed equality reports No difference;
a partial prefix never does. Data, absent and non-string pairs have no new action.
This is first differing Unicode scalar or end boundary, not byte-level offset
within a multibyte scalar, insertion/deletion alignment or a complete text diff.
Byte/scalar positions in the UI are one-based and refer to the scalar's beginning.

StringFirstDifference stores two immutable original strings, scalar indices and
common-prefix byte/scalar counters. Scalar equality compares original numeric
values, preserving exact UTF-8 spellings and composed/decomposed distinctions.
No normalization or source replacement occurs. Each explicit step consumes at
most32,768 UTF-8 bytes across both inputs combined; it reserves eight bytes before
reading a pair, so it can stop slightly short of that ceiling. Smaller test budgets
have an eight-byte minimum. No full-source byte array, prefix rescan, match history
or exhaustive per-keystroke comparison is introduced. Cancellation is checked at
entry/every64 pairs. Work is bounded per action; existing source/page-index storage
remains proportional to captured values. No elapsed-time or constant-memory claim.

FocusedStringDifference runs steps in cancellable detached tasks and guards output
with a request generation as well as cancellation. Restart/dismissal invalidate
old work. Captured selection identity owns a new pair session. Leaf preparation
handles a result that arrives before its page document is ready. Found positions
select each side's page independently; EOF clamps to that side's final page, marks
the closing quote and states that the string ends there. The differing scalar is
mapped into the existing escaped page (up to512 scalars). No full-string rendering.

Find queries/cursors/results remain independent and unchanged by comparison.
Explicit Find results choose their own highlight; Reveal Difference switches both
panes back and emits a presentation revision without rerunning the comparison.
Manual page navigation remains independent. Complete tagged copying, saved
provenance and path-free schema-1 exports remain unchanged.

Focused evidence:

- 501/502: specification compilation failures for missing new APIs, not reproduced
 behavioral defects or passing tests. No pre-existing behavioral defect confirmed.
- 503: `swift test --filter 'StringFirstDifferenceTests|FocusedStringDifferenceTests' -Xswiftc -warnings-as-errors`
 passed five new methods (three Core/two App). Covers composed/decomposed identity,
 emoji and page positions, exact highlighted scalar, prefix/end markers including
 a full final page, empty/equal pairs, byte-budget continuation, no early equality,
 independent Find, reveal revision, restart, terminal guards and a deliberately
 computed late difference after cancellation. The restart also supersedes old work.
- 504 and505: `./script/build_and_run.sh` built/staged/launched the actual app.
 Second build followed scalar-position wording clarification (not unchanged inputs).
 Final505 emitted no warnings. Development ad-hoc signing is not distribution proof.
- 506: synthetic late difference paused with explicit Continue Comparison, preserving
 an existing Previous suffix query/match and independent Current page.
- 507: Continue Comparison found scalar16386/start byte16386 (composed é versus
 decomposed e+accent), navigated both panes to page33 and highlighted each scalar.
 The original suffix query/result remained. Screenshot visually inspected. Native
 shaping can render composed/decomposed forms alike; original scalar ranges and
 values remain distinct, not normalized to the displayed glyph.
- 508/509: Find reused its original query/result; Reveal Difference restored the
 difference presentation without comparison work.
- 510: Previous512 emoji ended at scalar513/byte2049 while Current continued with x.
 Previous stayed page1/1 and revealed its marked closing quote with EOF label;
 Current revealed x on page2/2. Screenshot visually inspected.
- 511: equal original strings completed with explicit No difference.
- 512: Done/reopen reset pair comparison and Find state; development app open.

Accepted search479, renderer453/456/457, raw field, leaf copy139–144, page378–383
and parser/report/source-generation checks reused for unchanged boundaries. Only
new difference tests ran; no full suite, corpus/timing sweep, unchanged hashes or
signatures, accessibility, broad appearance work, Applications update, packaging,
release or push. Installed/public v0.1.20 remains unchanged; audit preserved.

## Exact Unicode Difference Details — 2026-10-17

Completed locally against a local development revision / released v0.1.21. After a first difference
is found, each pane displays Difference: U+XXXX plus an explicit Unicode escape,
and its original UTF-8 bytes in uppercase hexadecimal. Supplementary-plane code
points retain all required digits (for example U+1F642); byte display is at most
four bytes. Spaces, nulls, combining marks and zero-width characters are always
escaped in the detail label, avoiding invisible/bidirectional label content. The
original page rendering remains unchanged. EOF displays End of string with no
invented scalar, zero byte or blank byte row. Scalar/byte positions remain in the
comparison summary, one-based at the beginning of the scalar/end boundary.

The cursor captures its already-read original Unicode scalars in Position, where
byte counts now derive from those scalars. It does not rescan strings to recover
metadata, normalize code points, retain a substring/context window or increase the
32KiB combined per-step ceiling. StringScalarDetail formats only one scalar or EOF;
formatting has a fixed scalar/byte bound. Existing512-scalar rendering and complete
tagged copying remain intact. This is the first differing scalar, not full text
alignment or detection of all subsequent combining-mark differences.

Details belong to the same immutable position published under the existing request
generation/cancellation checks. Find/reveal/paging do not recompute them; the label
explicitly identifies the saved first difference even if Find reveals another match.
Cancellation or a fresh captured sheet removes the position and all details.
Saved provenance and path-free schema-1 exports remain unchanged.

Evidence:

- 526: new specification compiled before the API existed; retained missing-symbol
 failure, not a reproduced behavioral defect or passing regression assertion.
- 527: `swift test --filter 'UnicodeDifferenceDetailTests|UnicodeDifferencePublicationTests|StringFirstDifferenceTests' -Xswiftc -warnings-as-errors`
 passed six methods. Three new methods cover captured composed/decomposed scalars
after bounded continuation, four-byte emoji, null/space/zero-width/combining escapes,
EOF without bytes, fixed label bounds, a computed result arriving after cancellation,
and unchanged captured details across Reveal Difference. Three existing Core
methods were updated/rerun because Position now carries scalars rather than stored
byte counts; their Unicode/page/budget/empty/equal/prefix assertions remain intact.
- 528 `./script/build_and_run.sh` built/staged/launched the initial real app.
- 529: comparison continued to page33 and showed Previous U+00E9/C3 A9 versus Current
U+0065/65 while the shaped glyphs looked alike. Screenshot visually inspected.
- 530: prefix ending showed End of string, no byte value, and Current U+0078/78;
existing EOF/page reveal remained correct. Screenshot visually inspected.
- 531: same build command after a compact two-row detail refinement, with changed
view inputs. Final build emitted no warnings; no unchanged automated tests rerun.
- 532: final native layout showed U+0000/00 versus U+200B/E2 80 8B and explicit escapes,
including the invisible Current glyph. Screenshot visually inspected.
- 533: Done/reopen cleared saved comparison detail rows and Find state.

Accepted App first-difference guards503, independent Find/reveal508–509, search479,
renderer453/456/457, full copy139–144, page378–383, parser/report and other unaffected
checks reused. No full suite, corpus/timing sweep, unchanged hashes/signatures,
accessibility, broad appearance work, release, packaging, Applications update or
push. Installed/public v0.1.21 unchanged; development app open and audit preserved.

## Find Next Difference in Focused String Values — 2026-10-17

Find Next Difference resumes immediately after the saved scalar pair. It does
not compare normalized graphemes or align inserted/deleted text. Every unequal
scalar pair is a positional difference. The first prefix EOF is one terminal
result. Next completes without wrapping and says No further differences, retaining
the last result for Reveal Difference. Find First Difference resets cursor and
ordinal. Long equal intervals require explicit Continue Comparison within the
existing32KiB combined UTF-8 step ceiling; prior details stay visible while paused.

Previous and Current UTF-8 offsets diverge after unequal-width scalars, so the
cursor tracks them separately. Position.byteOffset is the Previous compatibility
coordinate; previousByteOffset and currentByteOffset explicitly identify the sides.
Highlight preparation uses the corresponding offset/width for each pane and its
existing bounded512-scalar page. Captured scalar/code-point/escape/UTF-8 details
and reveal revision publish together under cancellation plus request generations.
Next creates a fresh generation; stale next results cannot overwrite a newer first
request. Existing literal query/search/reveal state remains independent.

Evidence:
-614: `swift test --filter 'StringFirstDifferenceTests|FocusedStringDifferenceTests|UnicodeDifferenceDetailTests|UnicodeDifferencePublicationTests' -Xswiftc -warnings-as-errors`
 selected14 methods (six new/eight affected existing).13 passed; one new expected
escaped U+200B in rendered text, whereas the accepted renderer preserves its
original scalar and uses the separate Unicode detail label for an explicit escape.
This was an incorrect test expectation, not an app defect. Original receipt retained.
-615: corrected only that expectation; `swift test --filter 'StringFirstDifferenceTests.testNextTracksIndependentUTF8OffsetsAndHighlights' -Xswiftc -warnings-as-errors`
 passed. Other13 method results614 reused. New coverage includes unequal-width
scalar offsets and exact per-side display ranges across pages, composed/decomposed
adjacency, EOF, long intervals/continuation, independent literal Find, finished
state, restart, and a computed next result arriving after a newer first request.
-616: `./script/build_and_run.sh` built/staged/launched the real app without warnings.
An initial native attachment reached an older development process during staging;
it was closed and the current bundle selected without rebuilding or repeating tests.
-617: first a/emoji mismatch, then Next paused across5000 equal emoji; prior details
retained and Next disabled until explicit Continue Comparison.
-618: continuation revealed difference2 at scalar5002, Previous byte20002 and
Current byte20005; U+00E9/C3 A9 versus U+200B/E2 80 8B. Both page10/10, viewport
revealed, accented scalar highlighted. Invisible scalar remains original display
text with explicit separate metadata. Screenshot visually inspected.
-619: next emitted EOF versusx at scalar5003, independent byte starts20004/20008.
-620: next finished with No further differences, disabled Next and retained details.
-621: restart returned to first result/ordinal, both byte1/page1.

Fixture dist/string-next-difference-acceptance/StringNext.json is a synthetic
schema-1 pair. No inspected executable launched. Data594–601, fixed context575,
unchanged search479, renderer453/456/457, complete copy139–144, page378–383 and
parser/report evidence reused. No full suite, accessibility, timing/corpus sweep,
unchanged signature/hash rerun, release or push. Installed/public v0.1.25 unchanged.

Previous Found Difference now provides the same64-result bounded history for
strings and data; see FOCUSED_VALUE.md for the implementation/evidence635–643.
String entries retain original scalar identities and separate Previous/Current
UTF-8 positions. Replay restores the exact captured detail/highlight coordinate;
completion and scan frontier stay separate from the displayed historical result.

Jump to a Found Difference now directly selects retained string/data ordinals;
see FOCUSED_VALUE.md for bounded parsing, unchanged frontier and evidence656–665.
String selection restores both original UTF-8 coordinates and exact scalar details.
The taller focused sheet and minimum viewport fix the confirmed added-row clipping.

Copy Difference Details uses the current captured string/data mismatch with
exact scalar/UTF-8 or byte/EOF details and bounded context. No rescans or source
paths; clipboard output is limited to2048 UTF-8 bytes and guarded by focused
selection identity. See COPY_DIFFERENCE_DETAILS.md for scope and evidence678–684.

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

Reveal Text Match restores the captured original UTF-8 match page/highlight using
a separate display revision, without searching or changing cursor/direction. Saved
manual scalar/copy state remains intact; explicit Go/step returns to manual display.
Running/query/dismissal guards reject stale reveal. See TEXT_MATCH_REVEAL.md.

Copy Text Match Details records the last successful exact UTF-8 match with side,
byte range/length, scalar start, complete scalar escapes and bytes in at most16384
UTF-8 output bytes. Query/running/current-selection guards reject stale copies;
search/navigation/difference state remains intact. See COPY_TEXT_MATCH_DETAILS.md.
