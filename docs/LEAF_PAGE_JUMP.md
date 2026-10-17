# Go to Page in Focused Value

Completed locally 2026-10-17 against a local development revision / released v0.1.14.
Each prepared Previous/Current leaf pane now has Page number, Go and its valid
one-based range. Return submits from the field. First/Previous/Next/Last keep the
field synchronized. A valid number directly selects the existing document page;
there is no new value scan or indexing pass. Each side owns independent state.

Input accepts ASCII decimal digits, including leading zeros, within1…pageCount.
Empty, signed, fractional, whitespace-padded, non-ASCII and overflowing input is
rejected. Invalid submission leaves the current page unchanged and displays an
inline range message; editing clears feedback. Valid navigation normalizes the
field to the selected page. Empty strings/data and ordinary scalar values retain
one page; absent/container sides retain existing context without page controls.

LeafValueDocument and its bounds are unchanged:512 Unicode scalars/string page,
768 bytes/data page, escaped after slicing. Copy Leaf JSON still uses the complete
immutable captured leaf rather than the page. Async preparation remains off-main,
cancellable and guarded against late publication. Fresh sheet selection identity
resets all page/input/error state. No report/schema, input inspection, provenance,
source-generation, dependency or deployment-target change.

## Focused validation

- `swift test --filter LeafPageNavigationTests -Xswiftc -warnings-as-errors`
  passed two new methods378: invalid input preserves a prior middle page, editing
  recovers, zero-based conversion, existing-button synchronization, independent
  string/data navigation using existing documents, exact middle data bytes and
  fresh state. Accepted slicing/copy/parser methods were not rerun.
- `./script/build_and_run.sh` built/staged/launched the real development bundle379,
  Swift6/macOS14+ target on the selected native SDK. Its ad-hoc development
  signature is not a distribution readiness check.
- A small synthetic saved comparison supplies a four-page Previous string and
  five-page Current string. Native Go selected page2/page3 independently, showing
  PREVIOUS-MIDDLE and CURRENT-MIDDLE380. Screenshot380 visually inspected.
- Entering999 on Previous preserved page2 and Current page3 and displayed the
  valid1…4 guidance381. Initial automation expected adjacent page-counter text,
  but error layout split those native text elements; assertion corrected to check
  each counter independently. This was an assertion-oracle mismatch, not an app
  defect and no implementation changed. The same displayed state supplied the
  corrected assertion without repeating the interaction.
- Valid input4 with Return reached Previous page4, kept Current page3, cleared
  guidance, and disabled Previous-pane Next/Last382.
- Done then reopening the same leaf reset both fields/counters to1 and cleared
  error state383. Development app remains open.

Accepted leaf slicing/type/copy139–144, inspector/session252–261, report encoding,
saved parsing, reader generations and distribution366–377 reused for unchanged
boundaries. No full suite, timing/corpus sweep, unchanged signing/hash verification,
accessibility/appearance campaign, Applications update, packaging, release or push.
Installed/published v0.1.14 unchanged; untracked audit preserved.
