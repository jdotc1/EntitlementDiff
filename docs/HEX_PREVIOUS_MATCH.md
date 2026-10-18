# Find Previous Hex Match in Focused Data Values

Find Previous Hex Match completed locally (2026-10-18).
Each focused-data pane now offers Find Previous Hex / Continue Backward alongside
Find Next Hex / Continue Hex Search. Backward KMP reverses only the bounded query
and prefix table, scans original Data in reverse, and retains partial/overlapping
matches across explicit portions. Each portion reads at most32768 bytes; query
remains1–128 bytes. No source flattening, prefix rescan or automatic wrap/continuation.
Direction switches anchor at the currently displayed match and exclude its start:
backward starts at its end minus one; forward resumes at its start plus one.
This retains overlaps and avoids restarting from the beginning. Partial progress
continues in the active direction; a switch intentionally starts from the displayed
match. Beginning/end messages and disabled actions distinguish completion from pause.

Exact original byte range, bounded hex context and page reveal reuse the accepted
forward-search presentation. Manual byte/context/copy, other pane, selected
difference/history/frontier, schema1 reports, parser and requested architecture
remain independent. Query edits/dismissal reset direction, invalidate generation
and cancel work. Publication requires current generation and noncancelled task;
late uncooperative-runner results are discarded. No new OS API, platform,
dependency, permission, window dimension or report schema changes.


Four focused development tests passed. Native acceptance confirmed bounded backward continuation, exact matched bytes and page reveal, beginning/no-wrap behavior, forward resumption and independent manual/difference/pane state. Accepted checks are reused; no suite or accessibility work was rerun.
