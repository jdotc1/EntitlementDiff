# Copy Current Hex Match Details

Copy Current Hex Match Details completed locally (2026-10-18).
Each focused-data pane offers Copy Hex Match Details alongside Reveal Hex Match.
The record includes side, exact1-based inclusive range, length, all matched original
bytes and separately labelled up-to8-byte before/after context. Match capture reads
at most128 matched plus16 surrounding bytes; no source flattening or source-sized
copy. Output is path-free and limited1024 UTF-8 bytes at both model/action boundaries.
The complete captured record is independent of the16-byte/ellipsis display preview.
Copy uses last-successful match after pause/end, preserves cursor/direction/revision,
manual byte/context/copy and selected difference/history/frontier. Running search
cannot copy; query edits/dismissal clear record and retain generation/cancellation
guards. Clipboard action checks current focused-selection UUID immediately before
synchronous write and rejects stale/dismissed selection. No new async stage, OS
API, platform/dependency, window size, parser or schema1 report changes.


Four focused development tests passed. Native clipboard acceptance confirmed complete matched bytes beyond the display preview, exact ranges and side labels, bounded context/output, current-selection guards and independent search/navigation/difference state. Accepted checks are reused; no suite or accessibility work was rerun.
