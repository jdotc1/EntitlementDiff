# Inspector projection reuse

Completed locally 2026-10-16. Ordinary nested inspection retains one projection
for a selected entitlement and comparison revision. Re-evaluating the SwiftUI
view reads that projection rather than repeating traversal/search/paging.

InspectorProjectionSession captures the selected typed values and owns query,
Changes only, expanded paths and page transitions. It reconstructs ValueInspector
only after a relevant control change; unchanged controls and unavailable page
steps are no-ops. Query remains bounded to 256 Unicode scalars, page size 50,
traversal 2,000 nodes and depth 12. Controls that previously reset paging still do.

ChangeDetailView creates the session on appearance, outside body evaluation. The
existing comparison-revision and selection identities reset view state; explicit
revision/selection guards also prevent displaying a mismatched retained projection.
Source changes replace the entire session, including same-key replacement. There
is no asynchronous cache worker or delayed publication to race with replacement.
Existing native-read cancellation and request generations are unchanged.

Ordinary ValueInspector rows cache their change kind. Changes-only traversal reuses
its classification; otherwise only rows on the returned page are classified.
Branch navigation keeps lazy classification, so enumerating immediate children
still does not recursively compare their descendants. Full equality remains exact
and can traverse whole values: display limits are not an equality-time or allocation
bound. No elapsed-time speedup or hard responsiveness guarantee is claimed.

No parser, native reader, report encoder, browser projection, export boundary,
focused-value copying or provenance change. No path/state serialization added.

## Focused evidence

- `swift test --filter 'InspectorProjectionSessionTests|ValueInspectorTests|InspectorNavigationTests' -Xswiftc -warnings-as-errors`
  passed ten methods (252): four new retained-session methods and six existing
  inspector methods whose construction/classification path changed. Coverage
  includes no-op reuse, paging/search/expansion, same-key fresh values, Boolean vs
  Integer, exact large integer/string distinction, byte-distinct key identities,
  complete selected JSON, and explicitly incomplete bounded search.
- Final source review caught an introduced absent/absent Changes-only edge case.
  New `InspectorProjectionSessionTests/testChangesOnlyOmitsTwoAbsentValues` failed
  with two assertions in258. A narrow nil/nil guard restored the old omission;
  only that failed method reran and passed259. The ten accepted methods were reused.
- `./script/build_and_run.sh` built/launched the real development bundle253, then
  built/launched the nil/nil correction260. Swift 6, macOS 14+ target, macOS 27.2 SDK.
  Development ad-hoc signing is not distribution validation.
- Native254: selected structured example, unsigned maximum integer and Boolean to
  Integer distinction visible. Root collapse reduced seven rows to one.
- Native255: search samples opened collapsed descendants, rendered 50 rows,
  retained the incomplete-search notice and advanced to page 2.
- Native256: search [75] reset page and showed Integer 75 → 999; Changes only
  retained the matching row and ancestors. Screenshot inspected.
- Native257: Swap while search/Changes only were active preserved the same key,
  cleared query/checkbox/page state and displayed reversed values, including the
  unsigned maximum now Removed. Screenshot inspected. Final261 confirms the
  corrected development app launched with the expected initial guidance.

Unchanged branch navigation, leaf copy, reader generations, saved-report parser,
report/export and browser receipts remain accepted and reused. Original baseline32,
inspector54–63/145–150, focused values139–144 and branch navigation145–150 are
historical evidence with their original boundaries; no full suite was rerun.
No profiler/timing sweep, accessibility work, distribution signing/notarization,
Applications update, or push. Installed/published v0.1.8 unchanged. Audit directory
preserved. This is a local implementation and focused native acceptance record.
