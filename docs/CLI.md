# Command-line comparison

Build on macOS14+ with Swift6:

```sh
swift build --product entitlementdiff-cli
.build/debug/entitlementdiff-cli --previous /path/Before.app --current /path/After.app --architecture arm64 --output /path/new-report.json
```

Both app paths and architecture are required. Supported architectures are arm64 and
x86_64; no host default or fallback slice. Relative paths resolve against the working
directory; quote paths containing spaces. Use --help alone for usage. Unknown,
duplicate, missing and invalid options fail. JSON goes to stdout unless --output
names a new file. Diagnostics go only to stderr and may include filesystem errors;
the JSON report remains the existing path-free schema1. No text-summary mode yet.

Exit statuses:
-0: no entitlement-value or absent/present representation differences.
-1: differences found, including absent versus dictionary-present with no keys.
-2: argument, input, extraction, architecture, report, output or stdout-write failure.
A file-output success leaves stdout empty. A failure never emits a partial JSON
report to stdout; a stdout write failure can of course leave a partially written
stream. File output uses exclusive creation, never overwrite. A filesystem write
failure can leave a partial new file, returns2 and must not be treated as a report.
No atomic publication guarantee is claimed. Existing protected-destination ancestry/
symlink policy runs before extraction and again before file creation. As with GUI
export preflights, concurrent hostile filesystem mutation is not race-proof.

Uses SecurityEntitlementReader, ComparisonReport and ReportDestination unchanged.
Read-only main-executable metadata for the explicitly requested architecture;
no target-code execution, monitoring, signature validation or permission/trust
claims. Both extractions must succeed before report publication. Extraction failure
is never converted to empty entitlements. No GUI launch is required by the CLI.

The separate executable shares a dependency-free CLIKit runner for focused tests;
the actual Security entry point is macOS-only. The released app bundle includes the signed arm64 executable at
Contents/MacOS/entitlementdiff-cli. It shares the app ZIP and notarization.

MacScope NativeExportCLI request/publication boundaries were reviewed conceptually;
no MacScope code copied or dependency added. Existing MIT notices remain.
