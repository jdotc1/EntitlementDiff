# Next/Previous Change Navigation

Completed locally 2026-10-17. Previous Change and Next Change controls and matching
Comparison-menu commands review added/removed/changed entitlement rows in the
current visible sort order. Search/category preferences are never changed.

All Keys navigation skips unchanged rows. An unchanged selection moves to the
nearest change in the requested direction. Without a valid visible selection,
Next selects the first change and Previous selects the last. Endpoints do not wrap;
unavailable directions are disabled. The indicator describes visible changes,
not the full report: Change N of M in this view, or Visible changes: M.

ComparisonBrowser builds visible-index/change-index/ordinal maps alongside each
stored projection. Target lookup uses a binary search and current selection; no
filtering/sorting or source scans are added to body evaluation. Replacement,
filter/query/sort/reset rebuild these maps through the existing projection path.
AppActions checks current report/busy state and resolves the destination at action
time, then uses the existing exact-Find reveal ID/revision mechanism. No table or
inspector rewrite, captured stale row action, automatic filter widening, keyboard
shortcut override or report serialization change.

## Focused evidence

`swift test --filter 'ChangeNavigationTests|ChangeNavigationActionTests' -Xswiftc -warnings-as-errors`
passed four new methods312 (three Model, one App). Coverage: both no-selection
starts; unchanged skipping; endpoints/no wrap; reverse sorting; category/query
restrictions; current-source replacement/clear; byte-distinct UTF-8 identities and
large integers; busy guards; reveal identity; complete report JSON and comparison
revision unchanged. Existing reader/parser/generation/inspector/report checks reused.

`./script/build_and_run.sh` built/launched the real development app313, Swift6,
macOS14+ target, selected macOS27.2 SDK. Installed v0.1.11 was closed to target
this checkout's staged app; it was not replaced.

A new synthetic 100-key saved comparison in dist/change-navigation-acceptance has
changes at key000/key099 and 98 unchanged rows. Import uses existing validated
saved-report review, not inspected executable code or a new parser qualification.

- Native314: All Keys (100), Next selected key000, then skipped 98 unchanged rows,
  scrolled to key099, showed Change 2 of 2 and disabled Next. Typed 99 → 1099
  details and both saved provenance labels retained. Screenshot visually inspected.
- Native315: Previous returned to key000. After reversing key sort, Comparison →
  Next Change selected key099 as the first visible change with descending rows.
  Selection/counter/direction availability followed current ordering.
- Native316: query key000 limited results to one row; Next selected it, showed
  Change 1 of 1, disabled both directions, retained query/category and full totals
  (2 changes/98 unchanged). Screenshot recorded.
- Computer Use scroll/coordinate paths returned noWindowsAvailable despite the
  bound app continuing to respond to indexed controls. No app crash/hang observed.
  Native sorting used its indexed header after narrowing the view, then cleared
  query. Those transport failures do not establish a product defect.

Accepted browser133–138/151–153, exact Find200–205, filter recovery274–281,
inspector252/259 and reader/report/export receipts are reused for unchanged paths.
No full suite, repeated signature/hash checks, timing/corpus sweep, accessibility,
Applications update, distribution signing/notarization, release or push. Existing
untracked audit preserved. Installed/published v0.1.11 remains unchanged.
