# Previous/Next Scalar in Focused String Values

Previous/Next Scalar in Focused String Values completed locally (2026-10-17).
Per-pane manual scalar controls now offer Previous Scalar and Next Scalar beside
Copy Scalar Details after successful Go. Steps use captured last-success position,
not pending/rejected input; successful step updates input, exact scalar/UTF-8
metadata, highlight revision, page and copy payload together, clearing input error.
Prepared page checkpoints bound lookup to at most512 original scalars. No prefix
scan, normalization, comparison/search traversal or source-sized allocation.
First position disables Previous; EOF disables Next without wrap. Previous from
EOF returns to last scalar; empty string has only EOF. Before Go/reset no steps.
Panes remain independent. New search/running search and Reveal Difference retain
existing reset behavior; no new async stage. Search/difference cursors, history,
frontier, exports/schema1 and complete copying unchanged. No platform/dependencies
or sheet dimensions changed; new controls share existing copy row.


Four focused development tests passed. Native acceptance confirmed forward/reverse page crossings, exact combining and invisible scalar details, updated copy content, EOF stopping, pending-input independence and preserved search/difference state. Existing checks are reused; no suite or accessibility work was rerun.
