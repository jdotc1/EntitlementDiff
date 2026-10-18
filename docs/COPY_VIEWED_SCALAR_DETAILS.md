# Copy Viewed Scalar Details

Copy Viewed Scalar Details completed locally (2026-10-17).
Each manually viewed string scalar/EOF now offers Copy Scalar Details. Path-free
summary labels Previous/Current,1-based scalar and UTF-8 byte positions, exact
code-point/escaped scalar label and original UTF-8 bytes or explicit EOF. Original
Unicode representation is not normalized. Formatter uses only the captured position,
never source text, pending input or comparison/search cursors. Output is structurally
bounded and clipboard boundary rejects over1024 UTF-8 bytes. Invalid and unsubmitted
input preserves last-successful payload. Synchronous action requires current
focused-selection UUID and no active report write; stale/dismissed/reset contexts
cannot overwrite clipboard. Copying does not change page, highlight revision,
search state, selected difference or frontier. Existing new-search/match/reveal/
new-difference/dismissal resets remove corresponding manual copy actions.
No Core/parser/report/schema1/dependency/platform changes.


Three focused development tests passed. Native clipboard acceptance confirmed exact combining-mark and EOF details, pending/rejected input preservation, independent panes, search reset and unchanged selected-difference copying. Existing checks are reused; no suite or accessibility work was rerun.
