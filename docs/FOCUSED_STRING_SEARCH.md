# Find Text in Focused String Values

Completed locally 2026-10-17 against private0a666c8 / released v0.1.17.
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
