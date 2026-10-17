# Copy Exact Key

Completed locally 2026-10-16 on release-record baseline 0fe6508. This document records accepted feature evidence reused for v0.1.7 build 8;
distribution receipts are separate.

Copy Exact Key appears beside Copy Selected JSON for the selected entitlement
and in the Comparison menu. The menu is disabled without a visible selected row
or while another modal/report action is busy. The action resolves the model's
current selected row at invocation; the detail view passes no captured key.
Filtering, clear, replacement and ordinary selection reconciliation therefore
cannot cause an obsolete key to be copied.

The system plain-text pasteboard receives Data(key.utf8) using the string type.
No quotes, escaping, normalization, trimming or preview limit is applied. Empty
keys create an empty plain-text payload. Clipboard refusal produces an error and
no success status. An injectable writer permits action tests without touching the
user's general clipboard. Existing JSON, selected-value and full-report copy
paths are unchanged, as are parsers, encoding, saved provenance and schema 1.

## Focused evidence

`swift test --filter CopyExactKeyTests -Xswiftc -warnings-as-errors` passed three
new methods once (evidence/217). A unique native named pasteboard received and
returned identical UTF-8 data for composed/decomposed Unicode keys, whitespace,
control characters, empty text and a key beyond the 512-character display preview.
It was released afterward, without touching the general clipboard. Other cases
confirm current selection after changes, no write after filtering/clear or while
busy, clipboard-failure status, unchanged complete report JSON and saved provenance.

`./script/build_and_run.sh` built/launched the real GUI bundle (218).
Native acceptance observed Comparison > Copy Exact Key disabled without selection.
The selected parser-version button copied a key that pasted into Find as exactly
example.parser-version (219), without display quotes. Selecting network.client
then using the enabled Comparison-menu action pasted the new selected key instead
(220). The ordinary selected-detail layout was visually inspected (220 PNG).
These native UI copy actions intentionally updated the general clipboard.

Accepted browser/selection, exact Find, parsers, inspector and report/export
receipts are reused. No full suite, unchanged test/hash/signature rerun,
accessibility work, packaging, signing, Applications update or online push.
This is not minimum-OS/Intel-host or alternate-appearance qualification.
