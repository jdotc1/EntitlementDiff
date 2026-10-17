# Empty and partial comparison guidance

Completed locally 2026-10-16. The waiting view now describes the actual input
state and offers contextual actions through the existing AppActions methods.

- Neither input: Choose Previous, Choose Current, Open Saved Report, and the
  existing synthetic example entry point.
- One ready input: choose only the missing side; a saved Previous snapshot is
  explicitly described as a saved baseline.
- Failed input: name the failed side, offer Choose, and offer Retry only when a
  local source URL is retained. An empty opposite side can still be chosen.
- Loading: name the loading side or sides and retain Cancel and Clear.
- Report construction error: show Comparison unavailable and the actual error,
  rather than asking for two inputs as though neither had been selected.

ComparisonGuidance is a pure presentation projection in Model. It does not create
reports, perform inspection, retain paths, or mutate the session. ContentView
routes its typed actions through existing Choose/Reload/Open/Clear handlers.
Busy-state disabling is retained. Source-pane controls and successful-comparison
views are unchanged. Reader, request generations/cancellation, architecture,
typed values, browser selection, report schema and export paths are unchanged.

## Focused verification

- `swift test --filter ComparisonGuidanceTests -Xswiftc -warnings-as-errors`
  passed five new methods in evidence/233-comparison-guidance-tests.log. They
  cover empty/one-sided/saved inputs, failures with and without retained URLs,
  both failures, loading precedence and side names, and report-error guidance.
- evidence/232-comparison-guidance-tests.log is an initial compiler failure in
  the new test fixture (dictionary literal instead of EntitlementDictionary).
  Corrected before test execution; not a behavioral red/green result.
- `./script/build_and_run.sh` built and launched the changed development bundle
  (234), Swift 6, macOS 14+ deployment target, macOS 27.2 SDK. Development ad-hoc
  signing is not distribution validation.
- Native app evidence235: empty guidance and buttons; contextual Open Saved Report
  reached the existing native picker and report review.
- Native evidence236: adopted saved Previous; accurate saved-baseline guidance.
  Its contextual Choose Current opened the correct picker and inspection of the
  existing disposable Same.app fixture completed the comparison.
- Native evidence237: clearing Previous retained Current and requested Previous.
  Contextual Choose Previous opened its correct native picker.
- Native evidence238: selected a new empty Unreadable.app directory under
  dist/guidance-acceptance. Inspection failed; central Retry Previous Inspection
  ran and returned to the failed state with Current preserved, report copy/export
  disabled, and Choose Previous still available. No fixture executable launched.
- Screenshots235,236,238 were visually inspected for readable layout and visible
  contextual controls. Loading and both-failed states are covered by focused
  projection tests, not claimed as native visual acceptance.

Accepted checks are reused: baseline32; Reload/Retry87–93; saved baseline165–172;
saved comparison184–188; browser133–138; key copy217–220. No full suite, repeated
signing verification, accessibility work, release, push or Applications update.
The installed/published v0.1.7 is unchanged. The Computer Use app resolver initially
selected an older running instance; quitting that instance allowed inspection of
this checkout's changed development UI. This was a targeting issue, not an app defect.
