# Shared comparison and browser projection — 2026-10-15

Milestone 2 implementation on the `fce12a3` product baseline. Local planning
commit `ec0a6a6` records the preceding roadmap. No release/version change or push.

## Behavior and implementation

`ComparisonReport` now retains the one immutable `EntitlementComparison` it
constructs after validating the snapshots. `ComparisonModel.rows` reads that
result rather than running the comparison a second time. No unchecked report
initializer was added. Explicit CodingKeys exclude the internal comparison from
schema 1; JSON and text outputs retain their previous contents.

The session model owns `ComparisonBrowser`. It stores visible rows and an ID-based
selected-row lookup, and counts categories once when source rows are replaced.
Filtering/sorting recomputes only when source rows or actual query/category/sort
preferences change. Selection and view-body reads use the stored projection.
Reset updates all preferences before one recomputation. Source replacement always
refreshes values, even when every row ID is unchanged. UTF-8-derived IDs and
bytewise ordering remain unchanged.

The SwiftUI view uses native key-path bindings into model.browser. Selection
reconciliation is synchronous with projection publication, replacing the view's
repeated derived-row/onChange work. Swap publishes one final projection and keeps
selection if visible; loading, failure, clear and replacement remove obsolete
rows immediately. Existing reader generation/cancellation behavior is unchanged;
no background comparison stage or new concurrency mechanism was introduced.

Stateless library helpers remain available. Until a caller supplies rows through
`replaceRows`, preference changes do not perform implicit selection reconciliation.
This preserves legacy callers that pass their own rows to `visibleRows(in:)` and
call `reconcileSelection(in:)` explicitly.

This change does not cache nested inspector equality, raise traversal budgets,
add features or change accessibility. It removes identifiable duplicate work;
no measured native speedup or latency threshold is claimed.

## Focused verification

The first selected run passed ten methods: four browser projection methods,
model filter/invalidation and Swap checks, Reload cache invalidation, and three
report validation/serialization methods. The new schema compatibility method
compares the changed encoder's output directly with existing example JSON/text
fixtures; it does not regenerate or rehash those fixtures.

```sh
swift test --filter 'ComparisonBrowserTests|ComparisonModelTests/testSwapReversesAddedAndRemoved|ComparisonModelTests/testBrowserProjectionInvalidatesWithoutChangingReportContents|ReloadInputTests/testReloadRereadsSameURLArchitectureAndInvalidatesReport|CoreTests/testSharedComparisonKeepsSchemaOneExampleBytes|CoreTests/testReportRejectsArchitectureMismatchOrMissingIdentity|CoreTests/testReportEmitsOnlyChangesButBothCompleteSnapshots' -Xswiftc -warnings-as-errors > evidence/133-shared-comparison-focused-tests.log 2>&1
```

A separate read-only reviewer then identified a regression in the refactor's
legacy stateless API: changing preferences cleared a caller-managed selection
against an empty stored source. The new regression reproduced three assertion
failures in one method before the repair:

```sh
swift test --filter ComparisonBrowserTests/testStatelessHelpersPreserveCallerManagedSelectionUntilReconciliation -Xswiftc -warnings-as-errors > evidence/134-browser-stateless-regression-red.log 2>&1
```

The repair gates stored refresh on explicit source attachment, including an empty
replacement. Only the failed regression and the cached same-ID replacement case
affected by this gate were run afterward; both passed:

```sh
swift test --filter 'ComparisonBrowserTests/testStatelessHelpersPreserveCallerManagedSelectionUntilReconciliation|ComparisonBrowserTests/testReplacementWithSameIDsRefreshesSelectedValueAndCounts' -Xswiftc -warnings-as-errors > evidence/135-browser-stateless-regression-green.log 2>&1
```

This is eleven distinct passing methods across the accepted focused receipts,
with one changed-path repeat after the compatibility fix. It is not a complete
suite on HEAD. The other nine passes from 133 remain reused; unrelated Security,
decoder, export destination, packaging and release receipts were not rerun.
The original eight native extraction methods are unchanged and their accepted
receipt is reused. `script/verify.sh` was not invoked because it would repeat the
full debug/release suites and signature verification.

The real GUI target built and launched once after the final source changes:

```sh
./script/build_and_run.sh > evidence/136-shared-comparison-native-build.log 2>&1
```

The script staged the development bundle, checked its newly copied plist and
applied its normal local ad-hoc signature. It did not use a signing identity,
perform signature verification, notarize or update Applications. Native functional
inspection exercised filter/selection continuity, Swap value refresh, Reset,
reverse sorting and a category change that clears hidden selection. See
`evidence/137-shared-comparison-native-acceptance.json`.

```sh
/usr/bin/log show --last 5m --style compact --predicate 'process == "EntitlementDiff" AND (messageType == fault OR messageType == error)' > evidence/138-shared-comparison-runtime.log 2>&1
```

Runtime logs contain system-service messages and AppKit negative-geometry faults.
Historical `docs/GEOMETRY_DIAGNOSTIC.md` localized earlier faults of this class to
the system sharing indicator. That receipt is reused as context; no new stack
diagnosis or product attribution is claimed. Controls completed the changed
interaction sequence with no observed crash/hang. This is not fault-free-runtime,
minimum-OS, Intel-host, accessibility or performance qualification.

The fresh source review found no other material issue and confirmed that the
report schema and validation boundary remain intact. The scoped working diff
received a whitespace check before the local implementation commit.
