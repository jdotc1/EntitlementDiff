# Find Exact Child Key in Browse Branches

Completed locally 2026-10-17. Dictionary branches offer a raw Exact child key
field, Find Child Key and Clear Lookup. Matching includes case, whitespace, empty
keys and UTF-8 spelling; enter the raw key without JSON quotes. Arrays retain Go
to Index. Mixed containers retain separate Previous/Current structure navigation;
open a dictionary structure before looking up its children.

Core performs two lower-bound searches in immutable UTF-8-sorted immediate entry
arrays. Work is logarithmic in entry count, multiplied by key-byte comparisons;
no descendant scan, subtree equality, full merged ordinal computation or larger
search budget. The dedicated match retains original typed Previous/Current values
and uses the same immutable entry-position identity as paging. Labels/path tails
retain existing 256/512-scalar previews. Child pages remain capped at 50.
Input byte length and user-driven navigation history are not constant-memory claims.

A match can open a container or use the existing focused leaf inspector. Lookup
and missing results leave the current page unchanged; Up restores the parent page.
Editing or clearing the input, paging, opening a branch and Up clear the match.
Existing comparison revision/selection ownership destroys branch state on Swap,
Reload or saved adoption. Lookup is synchronous and has no late async result to
apply. Existing inspection generations and focused-view cancellation are unchanged.

Native UI inspection exposed two refinements during development. Branch controls,
match and children now scroll together so a short detail pane does not collapse
all child content. Canonically equivalent String edits initially retained an old
match. The input uses byte-sensitive equality and a narrow NSTextField bridge with
controlTextDidChange to deliver raw edits and immediately invalidate the match.
SwiftUI owns input/navigation; the coordinator refreshes its owner and releases the
delegate on dismantle. No permissions or accessibility features were changed.

## New focused evidence

- `swift test --filter 'InspectorBranchNavigatorTests/testExactChild' -Xswiftc -warnings-as-errors`
  passed two new Core methods (329): beyond 2,000 children, typed replacement and
  UInt64.max, page/open/back continuity, missing keys, distinct composed/decomposed
  identities, empty/space-bearing keys and result reset.
- `swift test --filter ExactChildKeyInputTests -Xswiftc -warnings-as-errors`
  assertion failed before the input equality repair (336), then passed (337).
- `swift test --filter ExactChildKeyInputTests/testNativeEditDeliversExactBytesAndInvalidatesLookup -Xswiftc -warnings-as-errors`
  passed one additional native edit-delivery/callback method (342). Four distinct
  new passing methods total; accepted methods were not rerun.
- `./script/build_and_run.sh` built/staged/launched real Swift6/macOS14+ development
  bundles (330 initial, 332 scrolling, 338 input equality, 339 native field final).
  These use development ad-hoc signatures, not distribution signing.
- Native synthetic saved fixture contains 2,102 child keys on each side. Initial
  fixture used an invalid unsigned type tag and was rejected; corrected to schema-1
  integer decimal text. This was fixture preparation, not an app defect.
- Container beyond the search prefix was found on children51–100 (331,333), opened;
  exact UInt64.max leaf reached existing Focused Value (334), and Up visibly restored
  children51–100 with cleared input. Accepted Core/page behavior reused after the
  isolated text-field bridge change.
- Native replacement of composed é by decomposed e+accent cleared the old match,
  then returned Previous Absent / Current Boolean true (340). Earlier observation
  335 records the composed old-only value; 336–337 record the regression.
- Missing lookup and actual final scrollable layout inspected (341 PNG/text).
  Swap removed captured lookup/branch state and displayed reversed sources (343).

Accepted branch145–150, inspector252–261, saved-report parsing/adoption184–188,
comparison navigation312–316, schema-1 export and generation receipts are reused
for unchanged boundaries. No full suite, performance sweep, accessibility campaign,
signing verification, packaging run, Applications update, release or push. Installed
and published v0.1.12 remain unchanged. The untracked audit remains preserved.

Receipt boundary: 334 and340 contain notes from the preceding visible Computer Use
responses; their initial capture returned only an unchanged-tree message. They are
not full hierarchy snapshots. 333/341/343 contain full state captures. Native tests
and builds remain separate evidence classes; no timing or broad appearance claim.
