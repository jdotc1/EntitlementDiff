# Tree Match Context Previews

Tree search results now include a prepared context excerpt. Up to24 Unicode scalars before/after and48 match scalars are captured from the retained UTF-8 match anchor. Controls are escaped; omitted context and a continuing long match are explicitly marked. Match delimiters distinguish the matching portion. The preview is display-only and may be visually elided; it is not a complete-value or identity record.

No source-prefix rescan or complete-value byte array is used. Preview fragments are prepared once per hit and reused by rows. Exact offsets, typed paths, complete copy records, Open Match and schema-1 reports remain unchanged. Existing query/scope/comparison generations suppress stale results.

Three focused development methods and native two-side preview/Open Match acceptance passed. Unicode, long-prefix and long-match bounds were checked in focused tests. Accepted unchanged checks reused; no suite or accessibility work rerun.
