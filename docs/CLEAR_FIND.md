# Clear Find in Focused Values

Each focused string or data pane offers Clear Text Search or Clear Hex Search.
Clearing empties that pane's query, removes its match, search context and Reveal/Copy
Match actions, and cancels pending work using request-generation guards. Late
results cannot restore cleared matches. No source scan is introduced.

Current page, last successful manual scalar/byte position, selected difference,
difference history and the other pane remain unchanged. Type fidelity, bounded
rendering and path-free schema-1 reports are preserved.

Three focused development tests passed, covering match/context removal, independent
panes, fresh search after clearing and rejection of late text/hex results. Native
acceptance confirmed retained scalar514/U+0301/CC81 and byte769/[80], page2 and
difference1. Accepted checks are reused; no suite or accessibility work was rerun.
