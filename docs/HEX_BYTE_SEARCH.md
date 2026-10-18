# Find Hex Bytes in Focused Data Values

Find Hex Bytes in Focused Data Values completed locally (2026-10-18).
Each data pane has Find Hex / Find Next Hex / Continue Hex Search. Queries accept
1–128 original bytes as ASCII hex pairs (case-insensitive), optionally separated
by ASCII spaces; contiguous pairs accepted. Odd nibbles, spaces within a pair,
nonhex, other whitespace, non-ASCII and oversized input rejected. Field retains
at most384 UTF-8 input bytes; parser reads at most385. No base64/text conversion.
KMP cursor retains at most128 pattern/failure entries and shares original Data;
each explicit detached portion reads at most32768 original bytes, with bounded
failure transitions and cancellation checks every256 reads. Prefix/suffix state
survives portion boundaries and found matches, preserving overlapping matches.
There is no wrap or automatic continuation. Incomplete/end messages differ.

Match selects its starting base64 page and shows exact 1-based full match range,
with at most8 preceding/8 following and16 bracketed matched bytes (ellipsis for
longer matches). No source-sized search output or flattening. Search state is
pane-local; query edits/dismissal invalidate generation and cancel work. Late
results require both current generation and noncancelled task. Existing captured
focused selection and preparation lifecycle retained. Manual byte/context/copy,
selected difference/history/frontier, report schema1, parser, platform and zero
dependencies unchanged. No new OS API or permissions.


Four focused development tests passed. Native acceptance confirmed exact matches and page reveal, bounded continuation and completed no-match results, malformed input, independent panes, preserved manual/difference state and clean reopening. Existing checks are reused; no suite or accessibility work was rerun.
