# UTF-8-safe Find Entitlement input

Completed locally 2026-10-17 against installed/released v0.1.13 and a local development revision.
Find Entitlement now shares the exact-byte native input boundary introduced for
child-key lookup. Core matching, AppActions, report encoding and browser projection
are unchanged. No dependencies, architecture or deployment-target changes.

## Confirmed defect and repair

A small synthetic saved comparison has an added `anchor` key and composed `é` key;
the decomposed `e` + U+0301 key is absent. Select anchor, filter to anchor, open
Command-F and Find composed é. The sheet correctly shows hidden-key feedback.
Replace its text with decomposed e+accent using select-all/paste. Before the fix,
feedback remained and another Find still treated the old composed spelling as a
hidden key. This contradicts the documented byte-exact edit/result contract.
Native observations357 and an explicit failing regression assertion358 precede
implementation changes. The same assertion passes after the repair362:

```javascript
function assertFindMissing(tree) {
    if (!tree.includes('No exact key found.') || tree.includes('Show in All Keys'))
        throw new Error('Regression: decomposed key is absent, but Find retained composed-key hidden feedback');
}
```

This is a native UI assertion red/green, not a claim that XCTest reproduced the
SwiftUI text-input coalescing. The saved failure includes the actual native state.

ExactChildKeyInput/ExactChildKeyField are generalized to ExactKeyInput/ExactKeyField.
Input equality and native edit callbacks preserve raw UTF-8 bytes. Every edit clears
lookup feedback directly; Find and Show in All Keys use the current input through
the existing AppActions method. This still resolves against current browser state,
selects/reveals only an exact match, and never silently widens filters.

The field has configurable placeholder and optional initial-focus/Return/Escape
callbacks. Find Entitlement requests initial focus once on attachment, deferred to
the next main-queue turn with weak ownership/window checks. Updates do not refocus.
Its coordinator refreshes the SwiftUI owner and releases the delegate on teardown.
Child lookup retains its original placeholder and native default command handling,
with no initial-focus request. There is no asynchronous key search or captured-row
lookup result to publish; modal source guards and reader generations are unchanged.

## Focused validation and reuse

- `swift test --filter ExactKeyFieldCommandTests -Xswiftc -warnings-as-errors`
  passed two new methods359. Raw composed-to-decomposed delivery clears feedback;
  Return receives current UTF-8 bytes, Escape cancels, unrelated commands fall
  through, delegate teardown clears ownership, and child defaults remain unhandled.
- `./script/build_and_run.sh` built/staged/launched the actual development app360,
  Swift6, macOS14+ target, selected native SDK. Ad-hoc signing is staging only.
- Native Command-F automatically focused the field. Return found the composed
  hidden key; changing to decomposed cleared old feedback361. Return then passed
  the identical formerly failing assertion362. Screenshot362 was visually inspected.
- Escape preserved the selected anchor row and `anchor` filter363.
- With descending entitlement sorting, explicit Show in All Keys selected composed
  é, cleared the filter, retained descending row order and showed typed integer2
  details364. Visible anchor lookup via Return selected anchor, dismissed the sheet
  and retained All Keys/descending order365. Reopening supplied fresh empty input.

Reuse exact-find Core checks200/202 and native203–205 for unchanged lookup/report
behavior; byte-input equality/edit receipts337/342 and branch Core329 for unchanged
semantics. Existing test names/types were generalized without rerunning those
accepted methods. Parser, saved provenance, schema-1 reports, source generations,
export protection, browser selection and distribution evidence remain accepted at
their original scope. No full suite, broad UI/appearance or accessibility campaign,
unchanged signing/hash verification, Applications update, packaging, release or push.
Installed and published v0.1.13 remain unchanged; the development app is open.
