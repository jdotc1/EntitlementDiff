# Open Saved Reports from Finder

Completed locally 2026-10-17. Finder → Open With → EntitlementDiff opens one local
JSON report into the existing saved-report review sheet. Open With → Other can
select a particular development bundle. Do not select Always Open With unless you
independently intend to change your document association; this feature does not
change the system JSON default.

The app declares public.json as Viewer with LSHandlerRank Alternate. AppDelegate
uses public NSApplicationDelegate.application(_:open:) to route file URLs into
AppActions.receiveSavedReportURLs. The existing picker uses that same boundary.
No NSDocument, custom URL scheme, persistent recent-file list or automatic
comparison adoption is introduced. A request received before action setup retains
only the first event, with at most two URLs sufficient to reject multiple files.

Exactly one local file URL is accepted. Multiple/empty/remote requests are rejected
before reading. Regular-file checks, schema validation and the 8 MiB/96-level/
100,000-node/1 MiB-string bounds remain in SavedReport. Production reads retain
Task.detached execution and balanced security-scoped access. A test-injected async
reader permits deterministic busy-read coverage without a parser rewrite.

Reading presents saved/unverified provenance and never replaces the session.
Cancel leaves the comparison untouched. Only the existing explicit Use as Previous
or Open Saved Comparison actions adopt data and invalidate prior native requests.
Busy requests (panel, export, import, focused value, lookup or report review) are
not queued; the existing action/review is preserved and the footer asks the user
to finish and open the report again. An existing error is not overwritten by a
new request. The delegate activates/reveals the comparison window when available.

## API evidence

Apple documentation: NSApplicationDelegate application(_:open:), macOS 10.13+:
https://developer.apple.com/documentation/appkit/nsapplicationdelegate/application-open
Queried through apple-docs using public symbols only. The selected macOS27.2 SDK
AppKit NSApplication.h declares application:openURLs: and explains its document-type
routing without NSDocument; native compilation confirms the Swift signature.
Swift 6/macOS14+ target and zero external dependencies remain unchanged.

## Focused verification

`swift test --filter FinderReportTests -Xswiftc -warnings-as-errors` passed five new
methods294. They cover review/cancel and explicit pair adoption; current report
bytes/revision/provenance; deterministic busy-read/review/lookup/error rejection;
malformed, directory, oversized and unsupported-schema requests through the actual
production reader; multiple/empty/remote requests; bounded first-event cold routing
and warm delegate delivery. Existing parser/type-fidelity/generation checks are
reused, not a new complete parser or integration-suite qualification.

`./script/build_and_run.sh` built/launched the real development bundle295.

- Cold native Finder acceptance: with installed and staged processes stopped,
  selected Examples/example-report.json, Open With → Other, exact staged app,
  Always Open With unchecked. Finder still listed Nova as JSON default. The
  computer-use result immediately showed the saved-report review sheet, before
  any adoption action. Process296 confirms the exact staged executable. Later
  captures296 are explicitly post-review and show an adopted baseline; that
  intervening adoption action was not captured and is not credited as acceptance.
- Warm native Finder acceptance297: loaded the synthetic pair, Finder Open With
  EntitlementDiff, observed saved-report review; Cancel retained the original
  non-saved pair and five-change count. No automatic session replacement observed.
- Invalid Launch Services acceptance298: `open -a` with the exact staged bundle
  and a new temporary schema-2 JSON file showed the expected invalid-report alert;
  dismissing it retained the comparison.
- Busy review acceptance299: while a valid report review was open, a second invalid
  file sent via `open -a` left the first review unchanged. Cancel returned to the
  original comparison with the finish-and-retry footer. No delayed read/alert.
  Screenshot299 visually inspected for layout and preserved comparison.

Native multiple-file gestures, closed-window reopening and other macOS versions
were not separately exercised. Multiple requests have focused policy coverage.
Accepted saved import165–172/184–188, generations87–93, key/type/report and browser
receipts are reused. No full suite, unchanged hash/signature checks, accessibility,
Applications update, distribution signing/notarization, release or push. Installed
v0.1.10 unchanged; pre-existing audit directory preserved.
