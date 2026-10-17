# Copy Branch JSON

Completed locally 2026-10-17 against private2afc50f / released v0.1.15.
Browse Branches now offers Copy Previous Branch JSON and Copy Current Branch JSON
for its current branch. The chosen array/dictionary is complete, including children
outside the visible page or search prefix. Empty containers are valid. Absent and
scalar sides are disabled; open a container's structure when types differ.

The clipboard contains the existing tagged EntitlementValue representation, without
a key/path wrapper. It is a value fragment, not a saved comparison report; Open
Saved Report is not intended to read this fragment. Full schema-1 report output
is unchanged and remains path-free. UTF-8 key identity, array order/multiplicity,
integer decimal precision and all value tags use the existing encoder.

AppActions validates comparison revision and current entitlement selection, captures
the immutable side's entire container before suspension and encodes off MainActor.
It checks revision/selection again before clipboard mutation. Superseding state
suppresses the write; UI actions that replace inputs use existing busy guards.
While copying, branch navigation/copy controls, Collapse and table selection are
blocked. Navigation pages and truncated labels never define the copied payload.
Status reports preparation, success, encoding failure, stale ownership or clipboard
rejection. Encoding/stale failure leaves the clipboard untouched. A clipboard
rejection after clear is reported, not represented as successful copying.

Rendering remains bounded to existing50 immediate children and preview limits.
Explicit complete copy encodes the complete container and allocates proportional
to its value, off-main; this is not a constant-memory or constant-time claim.
Branch changes and report replacement retain existing navigation reset behavior.
No public Core encoder API, dependency, target scope or source-read changes.

## Focused validation

- `swift test --filter BranchCopyActionTests -Xswiftc -warnings-as-errors`
  initial396 stopped on a test-only `await try` ordering compiler error; corrected
  to `try await`. No behavioral method ran in that attempt, no app defect/red-green
  claim. The corrected run397 passed three new methods.
- Coverage: complete typed118-key container from child page51+, Unicode byte variants,
  UInt64.max, ordered arrays, Previous/Current direction, unchanged complete report
  bytes, duplicate/busy refusal, Swap guard, empty versus absent/scalar, encoding
  failure preserving clipboard/recovery, stale revision/selection rejection and
  externally superseded async write suppression. Named native test pasteboards
  are released after use.
- `./script/build_and_run.sh` built/staged/launched the real development app398,
  Swift6/macOS14+ target on the selected SDK. Development ad-hoc signing is staging,
  not distribution verification.
- Native fixture has a nested Previous118/Current119-key dictionary plus a parent
  sibling. Exact lookup/Open Branch then Next Children reached children51–100.
  Native Previous copy showed success and preserved navigation399. `pbpaste`
  captured only the freshly requested synthetic output into399 JSON. Python parsed
  the new output and asserted all118 entries, first/last keys, distinct raw Unicode
  keys, UInt64.max, array order and exclusion of parent sibling/current-only data.
- Native Current copy showed success without leaving page51–100; captured JSON400
  parsed as119 entries with its exact current-only Boolean, excluding parent sibling.
  Screenshot400 visually inspected. These are new clipboard-output checks, not
  re-verification of sealed source artifacts. Computer Use had one invalidated
  duplicate Open Branch control; refreshing indices resolved it without app change.

Accepted encoder/report, parser/provenance, reader-generation, branch329/333–343,
leaf-copy139–144 and page378–383 receipts reused for unchanged boundaries. No full
suite, corpus/timing sweep, unchanged signing/hash verification, accessibility or
appearance campaign, Applications update, release, source packaging or push.
Installed/published v0.1.15 unchanged. Development app remains open; audit preserved.
