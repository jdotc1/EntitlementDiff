# Contextual Filter Recovery

Completed locally 2026-10-17. Empty comparison results now distinguish:

- Successful snapshots with zero keys: completed comparison, no recovery button.
- Matching entitlement values with unchanged keys: Show All Keys.
- Search hiding a populated category: Clear Search, preserving category and sort.
- Empty category while changes exist: Show All Changes, preserving sort.
- Empty category plus active search: explicitly Clear Search and Show All Changes
  or All Keys, whichever contains results. No silent preference changes.

BrowserRecoveryGuidance derives presentation from the stored browser counts and
visible projection. It does not rescan source rows or touch inspection/report data.
ComparisonBrowser.recover applies only the action appropriate to the current
empty projection, changes the necessary preferences together, then runs existing
projection/selection reconciliation once. It never resets sorting or invents a
selection. Visible results have no recovery guidance; stale/inapplicable actions
are no-ops. The existing full Reset View action is unchanged.

ContentView renders the guidance and a contextual button disabled during busy
modal/report actions. Saved data is described as snapshots, never as fresh native
inspection. Zero-key snapshots remain distinct from missing/failed inputs and from
no-change comparisons containing unchanged keys. Complete copy/export is independent
of all browser restrictions; schema 1, exact types/UTF-8 identities and counts remain
unchanged. No native reader, generation, parser, inspector or export-path changes.

## Focused verification

`swift test --filter BrowserRecoveryTests -Xswiftc -warnings-as-errors` passed five
new methods (274). Coverage includes search-only/category/combined recovery,
nondefault multi-column sorting, unchanged counts, cleared selection without
invented reselection, stale-action/source replacement guards, byte-distinct Unicode
keys, large integer fidelity, zero keys, and byte-identical complete schema-1 report
JSON plus unchanged comparison revision after browser recovery.

`./script/build_and_run.sh` built and launched the real development app (275).
Native acceptance used the existing synthetic example and three new disposable
saved-report fixtures in dist/filter-recovery-acceptance (Matching, AddedOnly,
ZeroKeys). Derived report claims are recomputed by the existing import path; these
are synthetic UI fixtures, not inspected executables or new parser qualification.

- 276: descending key sort, missing query, Clear Search restored five changes in
  descending order; category and complete comparison counts retained.
- 277: matching saved snapshots displayed no-change guidance; Show All Keys
  revealed five unchanged keys in descending order, with no automatic selection.
- 278: Removed (0) on an added-only comparison offered Show All Changes; an active
  query changed the action to Clear Search and Show All Changes. That action
  restored the one added row, cleared query and preserved the nondefault sort.
- 279: two saved empty dictionaries displayed completed zero-key guidance, no
  recovery action, and enabled complete copy/export controls. Saved/unverified
  labels remained visible. No fresh native-read claim.
- Screenshots276,277,279 were visually inspected for readable guidance and controls.
- A final text-only refinement uses count-neutral sentences to avoid singular
  grammar errors in the new messages. Logic/action/title inputs are unchanged;
  accepted tests and native flows are reused. Final real build280 and launch281
  passed. The updated sentence wording was compiled, not separately re-exercised
  through every accepted native state. Swift 6/macOS14+ target, macOS27.2 SDK.

Accepted browser133–138/151–153, saved-parser/import165–172/184–188,
selection/exact-copy200–205/217–220, inspector252/259 and report/export receipts
are reused for unchanged boundaries. No full suite, repeated signature/hash checks,
accessibility work, Applications update, distribution signing, release or push.
Installed/published v0.1.9 unchanged; existing audit directory preserved.
