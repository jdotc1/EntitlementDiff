# Find an Exact Entitlement Key

Completed locally 2026-10-16 against release-record baseline 2264150. This document records feature evidence reused for v0.1.6 build 7;
distribution receipts are separate.

## Workflow

Find Entitlement… in the comparison controls or Comparison menu (Command-F) opens
a focused exact-key field. Matching compares the complete UTF-8 byte sequence,
without trimming, case folding or Unicode normalization. Empty keys are supported.
Lookup runs once per explicit Find action, not on every keystroke.

A visible match selects the existing row and sends a new reveal revision to the
native SwiftUI table's ScrollViewReader. Repeating a lookup can reveal the same ID
again. Typed details follow normal selection. Missing matches leave filters and
selection intact. Hidden matches explain the active search/category boundary;
only Show in All Keys changes category to All Keys, clears search, keeps sorting
and selects/reveals the exact row. Confirmation recomputes the lookup against the
current stored source rather than trusting a stale captured row. Editing the key
clears the result by byte-sequence change, including canonically equivalent edits.

The modal action boundary blocks unrelated input/report actions while Find is open.
Command-F and the button require a comparison. Cancel is non-mutating. No source,
parser, comparison, encoding or saved-provenance change was made. Complete reports
remain independent of browser preferences. Existing accessibility semantics retained;
no accessibility work or permission changes undertaken.

## Focused evidence

- `swift test --filter ExactFindTests -Xswiftc -warnings-as-errors` passed the two
  initial new methods once (200): visible/missing/hidden, selection preservation,
  explicit reveal, counts/sort preservation, byte-distinct Unicode, whitespace,
  empty keys and source replacement.
- Only the subsequently added report-fidelity method ran:
  `swift test --filter ExactFindTests/testExactFindDoesNotChangeCompleteReportOrSavedProvenance -Xswiftc -warnings-as-errors` (202), passed once. It confirms complete JSON bytes and saved provenance remain unchanged after lookup/reveal.
- `./script/build_and_run.sh` built/launched the real GUI bundle (201).
- Native acceptance used one disposable synthetic saved report with 100 added keys
  and one unchanged key; no corpus/timing sweep. Parser recomputed deliberately
  empty supplied change claims. Command-F found example.key.099 below the initial
  viewport. Screenshot 203 visibly shows selected final row and integer(99) detail.
- Lookup of example.unchanged first showed the hidden-key explanation (204 hidden).
  Explicit Show in All Keys displayed 101 shown/100 changes/1 unchanged and selected
  that row (204 revealed).
- Missing example.missing showed the missing message; Cancel preserved All Keys,
  the selected unchanged key and counts (205 missing/preserved).

Accepted browser, report/export, saved-parser, provenance and distribution receipts
were reused. No full suite, unchanged test/hash/signature repeat, accessibility,
source packaging, signing, Applications update or push. No measured speedup,
minimum-OS/Intel-host or alternate-appearance qualification is claimed.
