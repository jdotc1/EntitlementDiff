# Native evidence reconciliation and delta acceptance

Updated 2026-10-14 for local Phase 1, based on private development main 5d81d3f
plus the scoped export/packaging/documentation delta. This worksheet records reused
receipts and new checks; it does not request a blanket acceptance rerun.

The revised handoff pin aa2e75c5 has matching affected ReportDestination source,
existing destination tests and package_source script except trailing blank lines.
The live checkout already contains Reload/Retry and Input Identity. The historical
consultant v0.1.0 patch stack was not applied. Optional Current-only Command-R and
accessibility changes are excluded. Info.plist remains v0.1.2 build 3.

## Evidence and decisions

| Capability | Accepted receipt / source identity | Phase 1 material delta | Decision and boundary |
|---|---|---|---|
| Baseline native/core integration | evidence/32, original 58 methods in debug and release including eight native methods; Apple silicon, macOS 27.2, Apple Swift 6.4 | Export ancestry policy only | Reuse unchanged coverage; no full suite |
| Export boundary | historical evidence/11–12, 23–26; v0.1.0 quarantined native export 81–83 | Retain entry ancestry as well as resolved target | New synthetic policy red/green 122–123; all four affected destination methods pass on macOS; not an exploit or concurrent-write reproduction |
| Current application build | metadata development build 105; release 111 | Core export source changed | New real development build/launch 126, macOS 27.2 build 26B5112a, Apple Swift 6.4.2, arm64; ad-hoc staging is not distribution signing |
| Ordinary save-panel export | accepted native export 81–83 | Production guard now checks both path interpretations | New synthetic-comparison save-panel export 129; new file created. Computer Use timed out reading completion status. Process sample 130 found the main thread waiting in the normal AppKit event loop; this does not establish all UI responsiveness. No new live-input denial/failure-recovery claim; production source retains validation before encoding/write and error/busy cleanup |
| Drops/replacement/cancellation | 44–52, browser 41–43, inspector 54–63 | None | Reuse accepted receipts; no gesture/corpus rerun |
| Reload/Retry | e0f5011, focused 87 and native 89–93 | None | Reuse; no optional command change |
| Input Identity | 51f058e, six focused methods 104 and native 105–110 | None | Reuse; UI identity stays out of schema 1 |
| Report contents/privacy | earlier report checks and exact unchanged bytes/schema test 104 | No schema or encoder change | Reuse full-report/path-free invariants |
| Source packaging | supplied candidate seven manifest methods, Linux Python 3.12, copied receipt 124 | Adoption of index/required-doc/versioned-output guard; docs copied verbatim | Reuse five unchanged methods; two temp fixtures resolve macOS roots and pass 128; new cleanup/refusal checks 125/127 |
| v0.1.2 distribution/install | sanitized tag 9b91dd7, evidence 111–121; local release record 5d81d3f | None to existing assets | Reuse signing/notary/ticket/Gatekeeper/download/install receipts; no rehash, re-signing or repackaging |
| Window lifecycle and commands | baseline native acceptance and inspector/reload receipts | None | Reuse; ordinary launch only accompanies changed core build |
| Minimum OS / Intel hosts | target macOS 14+, arm64 distribution; x86_64 input inspection is separate | None | Minimum-OS runtime, Intel-host and clean-Mac acceptance remain unestablished |
| Accessibility / alternate appearance | Existing features retained | Excluded | Work remains stopped; no complete acceptance claim |

## New-check details and limitations

Only changed export policy and packager outputs justify new checks. The regression
uses synthetic entry and target URLs, with no link/write fixture. It first failed
as an assertion with the target-only policy, then passed after both ancestry checks
were retained. Component identity and device/inode protection remain present.
The guard is a preflight, not race-proof containment or artifact custody.

New packaging tests use mocked index metadata and temporary synthetic files. Initial
cleanup tests stopped at preflight because macOS temporary roots resolve through
/var; the test roots were corrected, then only failed cases reran (127). The two
supplied temporary-file tests were similarly adapted and passed once on macOS (128).
The other five accepted manifest cases were not repeated. No real source ZIP was
regenerated. No published app, installed app, signature or old receipt was changed.

Raw evidence stays local and is excluded from source packaging. Public validation
summaries describe accepted observations without claiming a fresh complete audit.
A future release requires separate authorization and first checks for its new
artifact; this worksheet itself authorizes no push, signing or publication.
