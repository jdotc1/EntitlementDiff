# Bounded branch navigation

Milestone 4 completed locally 2026-10-15, based on milestone 3 commit `af81480`.
The explicit branch browser reaches values outside the search inspector's
2,000-node/12-level prefix without increasing that traversal budget.

## User workflow and scope

**Browse Branches** switches the selected entitlement detail to immediate children.
**Open Branch** enters a container; **Up** returns to its parent's saved child page.
**First Children**, **Previous Children** and **Next Children** navigate at most 50
immediate children at a time. Arrays additionally support **Go to Index**, using a
validated zero-based index. Invalid indices leave the current page unchanged.
A branch/page change resets scrolling to its first row.

The header identifies the branch level and a bounded tail preview of its path.
Previous/Current values remain paired by exact UTF-8 dictionary key or array index.
A dictionary/array type replacement exposes separate Previous/Current structures,
not invented key/index correspondence. Empty containers show no children; empty
scalar values remain selectable leaves. **View Value…** opens the existing exact
captured leaf viewer. **Copy Selected JSON** still refers to the entire entitlement.

The branch view has no Changes only or path search. It deliberately does not
recursively compare descendants or label containers unchanged. **Back to Search**
restores the existing query/filter and bounded inspector; its incomplete-search
notice persists as appropriate. Reopening Browse Branches starts from the root.
This is explicit browsing, not completion of an exhaustive search.

## Bounds and state

`InspectorBranchNavigator` stores immutable paired roots, an ancestor stack and
page cursors. Array indexing is direct. Dictionary pagination merges already
sorted entry arrays from saved offsets, consuming at most 50 merged keys per
step; it does not rescan earlier pages or flatten descendants. A page holds at
most 50 rows plus the displayed branch header. Labels use existing bounded,
escaped scalar previews. Dictionary identities use immutable paired entry offsets
within the captured snapshot; matching uses raw UTF-8, never preview text or
Swift canonical-equivalence String keys. Arrays retain original positional IDs.

These bounds cover child visits/rendered rows, not constant memory/time for
arbitrarily long keys or unlimited navigation. Key comparison cost depends on
key bytes. Ancestor and dictionary page history grow with user navigation. No
performance benchmark or new hostile-input isolation claim is made. Existing
parser, whole-comparison and report boundaries remain separate.

The session model supplies a report revision UUID on every report update. It is
not in the report or persisted. Combined report/selected-key SwiftUI identities
discard captured navigation for replacement, same-key Swap, clear, or selection
change; presentation-only query/sort changes do not create a new report revision.
No asynchronous navigation task is introduced. Leaf preparation/copy keeps its
existing cancellation and captured-value behavior.

## Executed evidence

- `swift test --filter 'InspectorBranchNavigatorTests|InspectorRevisionTests' -Xswiftc -warnings-as-errors`
  passed five new methods once in `evidence/145-branch-navigation-focused-tests.log`.
  They cover indices 2099/2100 and exact integer copying, 2,012 merged dictionary keys
  with distinct Unicode spellings, 20-level descent and parent-page restoration,
  type replacement/empty values, and report-revision invalidation versus browsing.
  These are a few synthetic cases, not a corpus or performance sweep.
- `./script/build_and_run.sh` built/launched the real app in 146. Native search for
  [2099] correctly stopped incomplete; explicit browsing reached that array slot,
  and View Value showed the exact path and integer 2099 on both sides. The new
  workflow screenshot was inspected. Copy reported success, but the later general
  clipboard read was not JSON; Computer Use subsequently required refresh after
  an external app change. Cause is unestablished. Claim UI completion only, not
  new clipboard-byte acceptance. No unexpected clipboard contents were retained.
- Native regression 147 was written before repair: scrolling to the root's samples
  row and entering it retained scroll offset, first showing [4] instead of [0].
  A view-only ScrollView identity keyed by branch/page fixes that behavior.
  `./script/build_and_run.sh` rebuilt that changed view in 148. All five accepted
  tests were reused; no unchanged test rerun.
- Native regression and page-transition checks then passed in 149: entering the
  branch showed [0] at scroll position 0; advancing a scrolled page showed [50] at scroll position 0.
  Swap discarded branch/page state and returned to the ordinary inspector with
  reversed values and empty query. The staged executable was observed directly.
- `/usr/bin/log show --last 12m --style compact --predicate 'process == "EntitlementDiff"'`
  captured 150 for both staged processes. It retains AppKit geometry faults and
  system-service errors. Historical sharing-indicator diagnosis is context only,
  not a new stack attribution. No crash/hang observed in these interactions.

A separate read-only reviewer found no consequential issue in cursor merging,
identities, immutable values, source invalidation, copy integration or the final
scroll identity fix. It ran no tests/builds/UI operations and made no edits.
Source review is not native acceptance or security certification.

Reuse accepted baseline 32; inspector/navigation 54–63; report/browser 133–138;
leaf 139/140 and native 142–143 for unchanged paths. Neither the complete verify.sh
suite nor the eight unchanged native reader methods were rerun. No schema/export
change, whole-export rerun, signature/dependency/hash check, corpus scan, minimum
OS/Intel acceptance, accessibility work, Applications update or push. The staged
build's ordinary ad-hoc signature is not distribution verification. Published and
installed v0.1.2 remain unchanged; no release artifact was produced.
