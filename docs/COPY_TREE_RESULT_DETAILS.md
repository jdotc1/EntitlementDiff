# Copy Selected Tree Result Details

Copy Selected Result Details records the selected hit's full entitlement key, side and typed path. Dictionary keys are complete Unicode scalar escapes; array indices are explicitly zero-based. It includes the original one-based UTF-8 byte and scalar starts, match byte length, full matched scalar escapes and UTF-8 bytes, plus complete/incomplete/limited search status. No normalization or shortened path substitution occurs.

Output is incrementally limited to 65536 bytes. Overflow rejects before clipboard mutation. Existing query, selection and comparison guards prevent stale copies. Selection and search continuation are preserved. Schema-1 reports are unchanged.

Two focused methods and native Previous/Current copy, partial/complete status and query-reset acceptance passed. Accepted matching, traversal, navigation, parser and report evidence reused. No suite or accessibility work rerun.
