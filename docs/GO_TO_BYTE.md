# Go to Byte in Focused Data Values

Go to Byte in Focused Data Values completed locally (2026-10-17).
Each data pane accepts its own 1-based decimal position through Go to Byte or
Return. Navigation shows the exact original byte with at most16 preceding and16
following bytes; the one-past-end position shows EOF, including1 for empty data.
The corresponding base64 page is selected directly; no data comparison, source
flattening or prefix scan occurs. Data indices remain relative to the original
value, including sliced Data with nonzero start indices. Manual context is clearly
labelled separately from the selected difference. Difference history/frontier and
Copy Difference Details remain unchanged. Reveal Difference/new difference
revision resets manual context/error/input and restores mismatch pages. Closing
and reopening the focused value clears navigation. No async stage was introduced;
existing preparation cancellation and generation guards remain.

DataByteNavigation inspects at most21 UTF-8 input bytes, stores a bounded prefix,
accepts1–20 ASCII decimal digits fitting Int and within1…count+1. Invalid, zero,
signed, whitespace, non-ASCII, overflowing or future input leaves context/position
and page unchanged, with an explicit valid-range error. Leading zeros accepted.
Pane state stores a compact context/offset, not another source buffer. Reports,
schema1, complete copying, macOS14/Swift6 and zero dependencies unchanged.


Four focused development methods passed, with native long-value navigation, EOF, invalid-input preservation, difference-copy independence, reveal and reopening acceptance. Existing parser, comparison, report and copy checks are reused. No suite or accessibility work was rerun.
