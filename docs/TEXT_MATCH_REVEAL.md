# Reveal Current Text Match in Focused String Values

Reveal Current Text Match completed locally (2026-10-18).
Focused string panes now offer Reveal Text Match after a successful literal UTF-8
search. A separate reveal revision restores the captured page/highlight without
searching, prefix rescans or changing the search cursor/direction/phase/message.
A pane-local display flag gives explicit match reveal precedence over saved manual
scalar highlighting while retaining its position/details/copy. Go/step scalar
returns to manual display; Reveal Difference returns to difference display. New
search/match retains accepted reset semantics; query reset clears match display.
Captured byte range and existing bounded string renderer preserve original UTF-8,
escaping and cross-page continuation. Running work cannot reveal; query edits and
dismissal invalidate match, retaining request-generation/cancellation guards.
No new async stage, platform/API/dependency, window dimension, parser or schema1 change.


Four focused development tests passed. Native acceptance confirmed exact cross-page Unicode highlighting, retained scalar details/copy, cursor and boundary-state preservation, query invalidation and independent panes. Accepted checks are reused; no suite or accessibility work was rerun.
