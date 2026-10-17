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
