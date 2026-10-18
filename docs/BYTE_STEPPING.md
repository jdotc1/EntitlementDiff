# Previous/Next Byte in Focused Data Values

Previous/Next Byte in Focused Data Values completed locally (2026-10-18).
Each manual data context now offers Previous Byte and Next Byte beside Copy Byte
Context. Steps use last-successful captured offset, not pending/rejected input;
update position/input/context/page/copy together and clear errors. Original bytes
and sliced Data indices are preserved. Each step regenerates at most33 bytes,
never scans a prefix or flattens source data. First byte disables Previous; EOF
disables Next without wrap. Previous from EOF returns last byte; empty data has
only EOF. Before Go/reset controls are absent. Pane state, selected difference,
history/frontier and difference-copy remain independent. Reveal/new difference
resets manual actions. No new async work, Core/parser/schema/platform/dependencies
or window dimensions changed; new controls share existing copy row.


Four focused development tests passed. Native acceptance confirmed forward/reverse page crossings, original byte context and updated copying, EOF/first boundaries, independent panes, pending-input independence and preserved selected-difference state. Existing checks are reused; no suite or accessibility work was rerun.
