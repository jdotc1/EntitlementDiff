Direct one-based page navigation added locally2026-10-17; see LEAF_PAGE_JUMP.md. Existing rendering/copy/preparation evidence below is reused.

# Focused value viewer and typed leaf copy

Implemented locally 2026-10-15 on milestone 2 commit `bc65b87`. This is the
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
