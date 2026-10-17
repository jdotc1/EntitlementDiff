# Report format v1

`ComparisonReport.jsonData()` emits a UTF-8 JSON document and final newline.
The outer object contains `schemaVersion: 1`, `tool: "EntitlementDiff"`, scope text,
`signatureValidation: "notPerformed"`, `gatekeeperAssessment: "notPerformed"`,
complete `previous` and `current` snapshots, `changes`, `unchangedCount` and notices.

Each snapshot has a source filename (not its file URL), signing identifier,
requested `architecture` (`arm64` or `x86_64`), `presence` (`dictionaryPresent` or
`notPresent`), `origin` (`extracted` or `syntheticExample`) and all entitlement
entries. A `.notPresent` snapshot may not contain entries. This is an extraction
representation flag, not a permissions or signature-validity verdict.

Each entry is `{ "key": <string>, "value": <typed value> }`. Dictionaries are
**arrays of entries**, sorted by UTF-8 key bytes, not JSON objects keyed by arbitrary
entitlement names. This preserves keys that differ in Unicode encoding but would
compare canonically equal as Swift Strings. Exact duplicate keys are rejected.
The convenience Swift `[String: EntitlementValue]` initializer cannot recover keys
that Swift already collapsed; use `init(entries:)` for byte-distinct key construction.

Typed values use `{ "type": ..., "value": ... }`:

| type | value | Contract |
|---|---|---|
| `boolean` | JSON Boolean | Never inferred from integer 0/1 |
| `integer` | Decimal string | Int64 range plus nonnegative values through UInt64.max |
| `real` | JSON number | Finite binary Double; distinct from integer, including signed zero |
| `string` | JSON string | Original decoded string, not escaped display copy |
| `data-base64` | Base64 string | Original decoded bytes |
| `date-reference-seconds` | JSON number | Finite seconds since 2001-01-01 00:00:00 UTC, possibly fractional |
| `array` | Array of typed values | Order and duplicate elements are significant |
| `dictionary` | Array of entries | Same sorted-entry contract recursively |

Integer storage width/signedness is not treated as a semantic change when the
mathematical value is equal. Real equality uses the underlying Double bit pattern;
string equality uses UTF-8 bytes. The JSON real tag requires downstream consumers
to preserve real-number semantics, including negative zero, rather than coercing
the token into an integer.

`SavedReport` provides bounded schema-1 import for saved baselines and complete
saved comparisons. Imported snapshots retain the report's `origin` field, but
are marked in session state as saved/unverified metadata; this is not a fresh
native inspection. The session-only saved marker and app identity metadata are
excluded from the schema-1 snapshot fields. Comparisons and notices are
recomputed from the imported values. See [Saved baseline](SAVED_BASELINE.md) and
[Saved comparison](SAVED_COMPARISON.md) for review behavior and import limits.

Every change includes `key`, `kind` and the applicable `previous`/`current` typed
values. For `added`, `previous` is **omitted**. For `removed`, `current` is omitted.
For `changed`, both are present. Absent is not encoded as null, false, zero or an
empty array. Unchanged entries remain in both snapshots but not `changes`.

Stable entry/key ordering and omission of timestamps/random identifiers make the
same report repeatable within the same toolchain/runtime. This is **not RFC 8785
canonical JSON**, a cryptographic signing format, or a guarantee of byte-identical
JSON across Foundation/Swift releases. Do not compare raw reports for security
attestation. Extracted input file paths are omitted, but entitlement values can
themselves contain paths or other sensitive data.

`report.schema.json` validates the structural contract; semantic bounds, Unicode
ordering, key uniqueness and cross-snapshot consistency remain application checks.
The schema is documentation/test tooling, not an external runtime dependency.
`Examples/example-report.json` is generated from the same Core implementation.

Source for Foundation date reference semantics: see SOURCES.md. Limitations of
upstream system decoding and unverified signature metadata apply to every report.
