# Open Saved Baseline

Completed locally 2026-10-16, based on release-record commit f8a6b0d. This is a
feature evidence record. Open Saved Baseline is included in release candidate
v0.1.4 build 5; distribution receipts are recorded separately.

## Workflow

Open Saved Baseline… in the toolbar or File menu (Command-O) opens one JSON file.
The review sheet selects Report Previous or Report Current, showing bounded name,
signing identifier, architecture and key count. It explicitly labels imported
metadata unverified and preserves synthetic-origin claims as claims.
Use as Previous replaces the session, cancels/invalidate generations for pending
reads, sets the chosen architecture and clears Current. Choose a fresh Current app
through the existing reader. Saved inputs have no app URL, Reload or Finder reveal.
Swap carries provenance and live URLs with their inputs. Cancel or failed import
leaves the session intact. No report URL is retained and no history is added.

## Parsing and fidelity

File reading and parsing run in a detached task with balanced security-scoped
access. Only local file URLs to regular files are accepted; reads cap at 8 MiB + 1
and reject above 8 MiB. A dedicated JSON container parser enforces at most 96
nested JSON levels and 100,000 value nodes, rejects duplicate object members and
trailing input, and limits decoded strings to 1 MiB. File size bounds raw scalar
allocation too. Foundation JSONDecoder handles only individual scalar tokens;
there is no whole-file unbounded Foundation JSON parse before these checks.
JSON structural depth includes schema wrappers, not just entitlement containers.
These are explicit import limits: a larger valid export can be refused.

Schema version 1, fixed tool/not-performed markers, strict field sets and tagged
value types are required. Exact decimal integers cover Int64/UInt64; nonfinite
reals/dates, noncanonical base64, duplicate UTF-8 entitlement keys, invalid snapshot
architecture/origin/presence and absent-with-entries are rejected. Byte-distinct
Unicode entitlement keys survive in entry arrays. Structural JSON member names
are schema names; canonically equivalent duplicate spellings are conservatively
rejected. Source names must be nonempty basenames up to 1024 UTF-8 bytes; signing
identifiers must be nonblank and at most 4096 bytes.

Imported changes/totals/notices are never authoritative. Their structures are
checked, then ComparisonReport validates the snapshots and recomputes results.
No new trust or signature claim follows. Path-like strings in entitlement values
are data and retain fidelity; no source filesystem location is imported/exported.

Session-only isSavedBaseline is excluded from explicit snapshot CodingKeys. The
schema-1 snapshot and top-level field sets are unchanged. The existing notices
array/text notes identify a saved snapshot as unverified and not a fresh read.
Live-only export semantics are unchanged; imported build identity is unavailable.

## Focused evidence

- `swift test --filter SavedReportTests -Xswiftc -warnings-as-errors`: four new
  methods passed once, evidence/165. Typed nested values, UInt64.max/Int64.min,
  negative-zero real, date/data, byte-distinct keys, schema fields, derived claims,
  malformed inputs/invariants, byte/depth/node/string budgets and capped read.
- Initial model-test compilation failed on an unnecessary try in the new test
  source (166), before behavioral execution. After correction,
  `swift test --filter SavedBaselineTests -Xswiftc -warnings-as-errors`: two new
  methods passed (167). Adoption clears live URLs/current, suppresses pending reads,
  switches architecture, labels saved provenance, preserves schema/path boundaries,
  and follows Swap/clear. Parser failures do not mutate the model.
- `./script/build_and_run.sh`: real development bundle built and launched (168).
- Native Command-O/file panel opened Examples/example-report.json. Review switched
  explicitly to Report Current/Example-After.app (169, including inspected screenshot).
  Use as Previous cleared Current and disabled exports. Native selection of the
  existing disposable Same.app fixture produced five removals against saved data;
  saved Previous and live Current labels are distinct (170).
- Native export completed with UI success (171 JSON). First inspection of that new
  file confirmed schema 1, five changes, saved provenance notice, no session paths
  and no additional snapshot fields.
- Unsupported schema fixture showed an actionable error. After dismissal the same
  saved/live snapshots and five changes remained, with export enabled (172).
  A transient Computer Use stale-state message was recovered by refreshing the app.

Accepted baseline, browser, inspector, reload, identity and distribution receipts
are reused. No full suite, unchanged signing/hash checks, accessibility work,
Applications update, source packaging or online push. No clean-Mac/Intel/minimum-OS
or hostile-filesystem containment claim. Import-size/resource policy is deliberately
separate from existing native decoder budgets.
