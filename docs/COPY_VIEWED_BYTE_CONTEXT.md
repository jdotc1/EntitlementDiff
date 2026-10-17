# Copy Viewed Byte Context

Copy Viewed Byte Context completed locally (2026-10-17).
Manual data contexts now offer per-pane Copy Byte Context. Formatting reads only
the last successful stored offset and captured original hex context, never field
input or source data. The path-free plain-text summary labels Previous/Current,
1-based position, context range and original hex bytes, with brackets marking the
viewed byte or EOF. At most33 source bytes are represented; the clipboard boundary
rejects output over1024 UTF-8 bytes. Pending edits and rejected positions retain
the saved payload. No source scan/page change/comparison/frontier mutation occurs.
The synchronous action checks current focused selection UUID and write state;
stale/dismissed selections and missing/reset context cannot overwrite clipboard.
Reveal Difference/new difference clears manual context and removes the buttons;
existing dismissal state reset applies. Complete JSON copy/schema1 exports unchanged.


Three focused development tests passed. Native clipboard acceptance confirmed last-successful-position behavior for rejected and unsubmitted input, independent sides and EOF, unchanged difference copying, and reset actions. Existing checks are reused; no suite or accessibility work was rerun.
