# Copy Current Text Match Details

Copy Current Text Match Details completed locally (2026-10-18).
Focused string panes offer Copy Text Match Details beside Reveal Text Match.
Copies side,1-based inclusive UTF-8 range, starting Unicode scalar position,
byte length, complete Unicode scalar escapes and all UTF-8 bytes. Every matched
scalar is represented as an explicit escape, preserving composed/decomposed,
invisible/control/quote/backslash identity without normalization. Literal UTF-8
search guarantees accepted query bytes equal captured source match; no source
prefix scan is needed. Query byte limit1024 is enforced before escape/hex expansion.
Output bound16384 UTF-8 bytes covers worst-case escaping plus hex and fixed headers;
no surrounding context or local paths. Both model and clipboard action enforce cap.
Copy uses last successful match, preserves cursor/direction/revisions/navigation/
difference/history and can copy completed/paused state. Running work rejects copy;
query/dismissal reset match; existing generation/cancellation guards remain.
Action checks current focused-selection UUID immediately before synchronous write.
No new async stage, OS API, platform/dependency/window/parser/schema1 change.


Four focused development tests passed. Native clipboard acceptance confirmed exact original scalar escapes and UTF-8 bytes, correct positions and side labels, bounded complete output, cursor preservation and current-selection/query guards. Accepted checks are reused; no suite or accessibility work was rerun.
