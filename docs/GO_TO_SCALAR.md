# Go to Unicode Scalar in Focused String Values

Go to Unicode Scalar in Focused String Values completed locally (2026-10-17).
Each prepared string pane accepts an independent1-based scalar position through
Go to Scalar or Return. Manual navigation reveals/highlights the original scalar
and displays code point, escaped notation, original UTF-8 bytes and1-based byte
position; one-past-last is EOF, including empty strings. Unicode scalars are not
normalized or merged into grapheme positions. Existing512-scalar page boundaries
and UTF-8 checkpoints are reused; the document records scalar count during its
existing cancellable off-main preparation. Each lookup visits at most512 scalars
on one prepared page, never scans the whole prefix or allocates a source-sized
scalar/byte array. Rendering remains512 scalars/page.

Input storage/parsing examines at most21 UTF-8 bytes;1–20 ASCII digits, valid Int
and1…scalarCount+1 required. Invalid/overflow/non-ASCII/signed/whitespace input
retains last position/revision/page. Pane-local manual state does not mutate
search query/cursor/match or selected difference/history/frontier/copy payload.
A new search or published match returns display to search; running literal search
disables manual Go. Reveal Difference/new difference clears manual state and
restores original mismatch. Existing sheet preparation cancellation suppresses
late publication after dismissal; no new async stage introduced. Sheet height
increased680→800 to retain readable viewport and all controls with new detail rows.
Swift6/macOS14, zero dependencies and schema1 exports preserved.


Four focused development tests passed after correcting a test-setup type error. Native acceptance confirmed exact Unicode and independent UTF-8 positions, invisible scalars, EOF, invalid-input preservation, search continuity and difference restoration. Existing checks are reused; no suite or accessibility work was rerun.
