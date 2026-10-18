# Reveal Current Hex Match

Reveal Current Hex Match completed locally (2026-10-18).
Each focused data pane offers Reveal Hex Match after a successful search. It
publishes a new reveal identity through the existing match-page selection path,
reusing captured match offset and exact bounded context without searching,
source reads or source-sized allocation. Search cursor/direction/phase/message,
manual byte/context/copy, selected difference/history/frontier and other pane
remain independent. Paused or completed search can reveal the last successful
match; running work cannot. Query edits/dismissal clear the captured match and
retain cancellation/request-generation guards. No new async stage, OS API,
platform/dependency, window dimension, parser or schema1 report change.


Four focused development tests passed. Native acceptance confirmed exact captured match reveal, page restoration, cursor and boundary-state preservation, query invalidation and independent panes/manual/difference state. Accepted checks are reused; no suite or accessibility work was rerun.
