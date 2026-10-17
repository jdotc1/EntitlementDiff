# Jump to Ancestor in Browse Branches

Completed locally 2026-10-17 against a local development revision / released v0.1.16.
Browse Branches offers Root and a compact Ancestors menu. Root restores the saved
root frame, including its child page. The menu lists at most12 nearest non-root
ancestors, closest first, with level and bounded existing label preview. Ordinary
Up remains available for all intermediate levels. Root/Up are disabled at root;
the menu is disabled when there are no non-root ancestors.

Destinations use opaque per-frame UUID identities plus level, not displayed labels
or parsed paths. Re-entering a branch creates a new frame identity, so a captured
old destination cannot resolve to the replacement frame. A jump validates the
actual stored ancestor, restores its entire frame/cursor/history, drops the deeper
stack and refreshes only the existing immediate-child page. It clears exact-child
results and UI array/key input/error state. Level previews do not merge Unicode
byte-distinct keys. UUIDs are session-only and do not enter reports or copied JSON.

Existing report-revision and selected-entitlement ownership resets captured branch
navigation for replacement, Reload, Swap and saved adoption. No asynchronous search
or new subtree traversal is introduced. Menu construction inspects at most12 frames;
stack truncation still costs proportional to dropped navigation history. Child
rendering remains50/page. No new constant-memory or timing claim. Branch copy uses
the restored complete typed root through its existing revision/selection guards.
Paging buttons use a second row to keep the ancestor controls compact.

## Focused validation

- `swift test --filter InspectorAncestorTests -Xswiftc -warnings-as-errors`
  initial413 stopped on a missing `try` in the new test's XCTUnwrap call. Corrected
  test-only syntax; no behavioral methods ran in that attempt. Corrected414 passed
  three new methods. No production defect/red-green claim.
- Tests cover dictionary page/history restoration and Previous/Next continuity,
  exact-child clearing, direct-index array cursor restoration,18-level navigation,
  maximum12 menu entries, raw Unicode label variants, unique/stale identities,
  stale destination rejection after re-entry, and new navigation ownership.
- `./script/build_and_run.sh` built/staged/launched real Swift6/macOS14+ development
  app415. Native level3 menu offered level2 [93] and level1 k050. Direct level1 jump
  restored array index93/children94–120 and blank array input416. Root restored the
  dictionary page children51–100 and disabled root controls417. These observations
  do not depend on whole-tree equality or raised search budgets.
- Screenshot417 exposed a stretching menu; a `.fixedSize()` layout refinement was
  compiled/staged/launched418. Screenshot/state419 visually inspected compact
  controls. Accepted Core and parent-page interactions414/416–417 reused after the
  layout-only change. No unchanged test rerun.
- Native Swap from a populated branch removed its captured controls/navigation
  and showed reversed inputs420. Full source/selection ownership follows the
  unchanged existing detail revision/reset mechanism.

Accepted branch329/333–343, copy397/399–400, parser/report/type fidelity and reader
request-generation checks reused. No full suite, corpus/timing sweep, unchanged
hash/signature verification, accessibility or broad appearance campaign,
Applications update, source packaging, release or push. Installed/published v0.1.16
unchanged. Development app open; historical untracked audit preserved.
