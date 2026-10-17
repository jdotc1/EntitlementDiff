# Open Saved Comparison

Completed locally 2026-10-16, based on v0.1.4 release record 6dead48.
This document records the local feature evidence reused for v0.1.5 build 6.
Distribution receipts are separate.

## Workflow

Open Saved Report… in the toolbar or File menu (Command-O) retains the bounded
report reader and review sheet. The sheet shows a bounded saved pair name preview,
the existing per-snapshot baseline choice and a separate Open Saved Comparison
button. Use as Previous remains the default keyboard action, preserving the
baseline workflow. Cancel remains non-mutating.

Open Saved Comparison adopts both validated snapshots, invalidates/cancels prior
live reads, removes their retained URLs, selects the report architecture and
recomputes the comparison. Both panes explicitly show saved/unverified provenance.
No input app URL or report-file URL is retained for saved snapshots; Reload and
Finder reveal are unavailable. Browser/report/inspector operate on the same
validated comparison as live inputs. Either side can be replaced through normal
native selection/drop; only that new live side gains Reload/Reveal.

Clear first invalidates old report/navigation identities and removes visible
selection. Publication of the saved pair creates a new report revision; prior
inspector state cannot refer to the old pair. Swap carries snapshots and live URLs
with their sides. Preferences remain session preferences; filters never alter
complete exported snapshots or changes.

## Preserved boundaries

SavedReport parsing and Core report encoding were not changed. Reuse the accepted
8 MiB / 96 JSON levels / 100,000 value nodes / 1 MiB-per-string parser checks and
typed conversion/invariant validation. Model adoption takes a SavedReport, whose
public construction path has already validated both snapshots. Imported derived
claims are still recomputed and saved provenance still uses the existing schema-1
notices. No new schema field, source location, decoder budget, dependency,
architecture fallback, persistent history or target execution was introduced.

## Focused evidence

`swift test --filter SavedComparisonTests -Xswiftc -warnings-as-errors` passed two
new methods once (evidence/184). They cover pending previous/current reads completing
after adoption, architecture/report revision, saved labels, zero retained live URLs,
counts, complete recomputed JSON equality, filter-independent exports, Swap, a live
replacement with correct saved provenance, path-free schema 1 and architecture clear.

`./script/build_and_run.sh` built/launched the real development app (185).
Native Command-O selected the existing Examples/example-report.json. The review
layout and distinct baseline/comparison buttons were visually inspected (186).
Open Saved Comparison immediately showed Example-Before/After, both saved labels,
five changes/one unchanged, exports enabled and Reload Both disabled (187).
The feature-label array inspector showed ordered paired values. Replacing Current
with the existing disposable Same.app fixture preserved saved Previous, enabled
only live Current Reload, produced five removals and cleared obsolete details
(188). A transient Computer Use stale-state message was recovered by refreshing
the picker before entering the task's path; no unrelated project file was opened.

Existing parser 165, baseline/model 167, native saved report/export/failure recovery
169–172, browser/inspector and v0.1.4 distribution receipts are reused. No full suite,
unchanged tests, export/signature hashes, accessibility, source packaging, signing,
Applications update or online push. No native performance, alternate-appearance,
minimum-OS, Intel-host or clean-Mac claim.
