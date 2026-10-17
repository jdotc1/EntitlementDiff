Direct one-based page navigation added locally2026-10-17; see LEAF_PAGE_JUMP.md. Existing rendering/copy/preparation evidence below is reused.

# Focused value viewer and typed leaf copy

Implemented locally 2026-10-15 on milestone 2 local development. This is the
explicitly authorized milestone 3 scope: long-value viewing and exact scalar copy.
All Keys and deeper-tree navigation remain separate future work.

## Behavior and implementation

Each inspected row with a scalar on either side offers **View Value…**. The sheet
captures Previous and Current values when opened, labels their types, and supplies
independent First/Previous/Next/Last controls. Strings use 512 Unicode scalars per
page, slicing before display escaping; data uses 768 bytes per page rendered as
base64. Empty strings/data have one page. Scalar boundaries preserve original text
bytes when reconstructed; a combining sequence may span pages. This is a text
inspection view, not an editor. Existing tree traversal/preview limits remain.

String-page indexing runs in a cancellable detached task. Rendering reads only the
chosen page (at most 4,098 escaped scalars for strings, 1,024 base64 characters for
data). The page index still grows with total string length; this is not a constant
memory or benchmark claim. Each presentation has a fresh UUID, preventing a later
selection from retaining old document/page state. Dismissal cancels preparation
and a cancellation check prevents late publication.

**Copy Previous/Current Leaf JSON** encodes the complete captured side with the
existing tagged `EntitlementValue` encoder, off MainActor. It preserves the exact
integer strings and Boolean/string/data/date/real tags. No key/path wrapper is
added. Current page and display escaping never define the payload. Absent sides
and containers cannot be copied as leaves; their context remains visible. The
existing whole-entitlement **Copy Selected JSON** action remains available.

Source/report actions are blocked while the sheet is open. Concurrent copy and
sheet dismissal are disabled while encoding/copying. An encoding failure reports
an inline error, restores controls and leaves the clipboard untouched. A native
clipboard rejection is reported separately after attempting the write. No history,
files, source mutations, schema changes, new dependency or inspection scope added.

## Executed validation and reused evidence

1. `swift test --filter 'InspectorLeafTests|LeafCopyActionTests' -Xswiftc -warnings-as-errors`
   in `evidence/139-leaf-viewer-focused-tests.log`: seven new methods compiled and
   ran; six passed. One signed-zero assertion failed because the test parsed JSON
   through `JSONSerialization`/`NSNumber`, which inferred an integer zero. The
   test oracle was corrected to decode the tagged real as `Double`. Production
   encoding was unchanged; this is not a production red/green defect claim.
2. `swift test --filter InspectorLeafTests/testTypedScalarsAndEmptyLeavesDoNotBecomeContainersOrAbsent -Xswiftc -warnings-as-errors`
   in `evidence/140-leaf-signed-zero-typed-decode.log`: only that changed method
   reran and passed. Reuse the other six passes from 139: seven distinct passing
   methods total. Coverage includes suffix reachability, scalar/UTF-8 fidelity,
   escaped controls, sliced data/base64, exact integer extremes, signed zero,
   empty-versus-absent/container, captured side copy, concurrent-copy refusal,
   encoding failure recovery and private pasteboard contents.
3. `./script/build_and_run.sh` in `evidence/141-leaf-viewer-native-build.log` built
   and launched the real staged development bundle. Its usual ad-hoc signature is
   a build step, not Developer ID/signature verification or distribution proof.
4. Native Computer Use opened the long-text leaf, inspected both third-page
   differing suffixes and copied Current from page 3. The newly produced clipboard
   decoded to the exact original 1,331-character typed string (142). Dismissal and
   a different selection showed fresh Page 1 of 1, the complete UInt64 maximum and
   disabled absent-side copy. Screenshot inspected for the new sheet; native
   observations and staged executable identity are recorded in 143.
5. `/usr/bin/log show --last 8m --style compact --predicate 'process == "EntitlementDiff"'`
   captured 144. It contains previous/current-process system-service messages and
   AppKit geometry faults. The historical sharing-indicator diagnosis remains
   context only; no new stack attribution was performed. No crash or hang was
   observed during these interactions. This is not a fault-free-runtime claim.

A separate read-only in-thread reviewer inspected the final implementation and
found no consequential source defect. Its signed-zero test-oracle concern was
resolved by 140. It performed no checks or mutations. The scoped review covered
paging/cancellation, identity, scalar eligibility, captured copy, busy guards and
macOS availability; it is not a security certification.

Accepted baseline 32, inspector/navigation 54–63, report/schema and browser
133–138 remain reused for unchanged boundaries. No full `verify.sh` suite, eight
native extraction methods, unchanged signing/dependency/hash check or corpus run
was repeated. No performance benchmark, minimum-macOS-14/Intel acceptance,
accessibility work, install, notarization, release packaging or push. Published
and installed v0.1.2 remain separate; no new distribution claim.

## Find First Difference in Focused Data Values — 2026-10-17

When both captured values are data, Find First Difference begins at the original
bytes. Continue Comparison explicitly examines another bounded portion; partial
agreement never becomes a No difference result. A mismatch reports its original
one-based byte position and each side's uppercase hexadecimal byte. End of data
is explicit and distinct from00. Empty/equal values remain valid. Mixed, absent
or non-data pairs do not receive this data action; string comparison/search keep
their existing workflow. This locates the first byte difference, not an aligned
binary diff or a decoded format comparison.

DataFirstDifference retains immutable Data values, native Data indices and a
relative byte offset, including Data slices whose startIndex is not zero. It does
not flatten full byte arrays, decode/re-encode base64, compare display text or
rescan a prefix for each continuation. Steps read at most32,768 original bytes
across both inputs combined, reserving two bytes per pair; smaller test budgets
have a two-byte minimum. Cancellation is checked at entry/every256 pairs. Storage
and the captured value size remain separate from this per-action work budget;
no constant-memory or elapsed-time claim is made.

FocusedDataDifference owns a separate MainActor session and cancellable detached
steps. A request generation as well as cancellation guards every publication.
Restart/dismissal invalidates cursor, result and work. Existing captured selection
identity creates fresh state. A result arriving before leaf preparation is applied
when its document becomes ready. Original byte offset maps to the existing768-byte
base64 page; each side independently clamps an EOF boundary to its last page.
Reveal Difference only changes presentation revision and restores/reset-scrolls
those pages. Manual paging remains available. Base64 characters are not highlighted
as individual original bytes. Exact byte/EOF details identify the saved difference.
No new encoding, report schema, saved provenance or clipboard contract is introduced;
Copy Leaf JSON still contains the complete tagged original value.

Evidence:

- 552: specification compilation before the new APIs existed. Missing-symbol
 failure is not a behavioral regression failure or a passing test.
- 553: `swift test --filter 'DataFirstDifferenceTests|FocusedDataDifferenceTests' -Xswiftc -warnings-as-errors`
 passed five new methods (three Core/two App), covering later-page7F/80 identity,
32KiB combined cap, explicit small-budget continuation, equality only after all
bytes, empty/prefix EOF versus00, nonzero-index Data slices, independent restart/
reveal state, terminal guards and a deliberately computed byte result returning
after cancellation. No pre-existing behavioral defect was confirmed.
- 554: `./script/build_and_run.sh` built/staged/launched the actual development
bundle without warnings. Ad-hoc development signing is not distribution proof.
- 555: synthetic data pair paused with explicit Continue Comparison and no result.
- 556: continuation found original byte20001, Previous7F/Current80, and navigated
both panes to page27 of27. Existing base64 display remained unhighlighted;
screenshot visually inspected.
- 557: manual Previous First page followed by Reveal Difference restored page27
without starting comparison again.
- 558: Previous ended after768 bytes while Current continued with00. The summary
reported byte769; Previous clamped to page1/1 and Current opened page2/2. No false
zero byte was assigned to EOF. Screenshot visually inspected.
- 559: equal original data completed with explicit No difference.
- 560: Done/reopen cleared saved data comparison and detail state. App open.

Accepted string comparison503, Unicode metadata527/531–533, search479, scalar
renderer453/456/457, full leaf copying139–144, page378–383 and parser/report/
source-generation checks reused for unchanged boundaries. Only the five new data
methods ran. No suite, corpus/timing sweep, unchanged hashes/signatures,
accessibility, broad appearance work, packaging, release, Applications update or
push. Installed/public v0.1.22 unchanged; unrelated audit preserved.
