# Copy Current Difference Details

Copy Current Difference Details completed locally (2026-10-17).
Focused string/data inspectors now offer Copy Difference Details beside Go to
found difference. Synchronous formatting reads only the displayed captured result;
no source scans, history traversal, page changes or frontier changes occur.
String summaries identify ordinal, 1-based scalar position, separate 1-based UTF-8
byte positions, exact escaped code points and UTF-8 bytes, including explicit EOF.
Data summaries identify ordinal/byte, exact hex bytes or EOF, and the existing
at-most33-byte context per side. No keys, file paths or preview paths are included.
Output is structurally bounded and the clipboard boundary rejects over2048 UTF-8
bytes. Copy availability follows settled difference/finished state; running,
paused, reset and empty states expose no payload. The action requires the current
focused selection UUID; stale/dismissed selections cannot overwrite the clipboard.
Invalid jump input preserves the selected result and its copy payload. Existing
schema-1 exports and complete leaf/branch/entitlement JSON copying are unchanged.


Four focused development tests passed, including native pasteboard boundary coverage. Native string and data copy acceptance confirmed exact selected-result content and readable controls. Existing history, parser, report and rendering evidence is reused. No suite or accessibility work was rerun.
