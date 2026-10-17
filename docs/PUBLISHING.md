# Source publication: evidence-preserving workflow

Adopted locally for Phase 1 against private development main 5d81d3f on
2026-10-14. The reviewed source pin aa2e75c5 matches the affected implementation
files apart from trailing blank lines. This is not a new release receipt.

## 1. Reconcile once

Use the builder's already-established candidate revision, working-tree state,
release inventory and native receipts. Map each proposed change to that state.
Keep prior results with their original date, revision, environment and scope.
Do not rerun completed native acceptance, acquire old assets again or recalculate
old checksums just to reproduce the consultant report. An unavailable receipt is
an evidence limitation, not proof that a check failed.

A publication-documentation change does not itself invalidate the application's
native receipts. For a genuine new code change, identify the affected invariant
and add only the focused, authorized check needed to cover it. Record any remaining
uncertainty. A new full native gate requires a specific reason, not the age of this
audit. See [MACOS_ACCEPTANCE.md](MACOS_ACCEPTANCE.md).

## 2. Prepare an intentional source selection

Use Python 3.9+. This local checkout retains private development history. Commit
local work here, but publish only the sanitized source tree through the existing
publication history when separately authorized. Never push this private main.
The packager reads approved Git-index paths but copies their current working-tree
bytes. It is not `git archive`, a commit attestation or a reproducible-build tool.
Untracked files are omitted; selected missing files fail. Selected merge conflicts,
Gitlinks/submodules and symlink index entries are rejected by the guard;
ordinary and executable file modes are supported. Filesystem symlinks and symlinked
ancestor directories are also rejected. Do not mutate the checkout while packaging.

The acceptance checklist, release-validation/reload documents and Info.plist
are required tracked inputs. They are copied unchanged, not regenerated from hard-coded historical text.
Before release, associate the clean candidate with its existing recorded revision.
Dirty-tree packaging is possible for local review, but must never be described as
an export of that commit. Inspect the selected content, including any tracked files
under Sources, Tests, Examples, script and Resources. Those directory prefixes do
not guarantee that every nested log, archive or personal instruction is excluded.

## 3. Package only when the builder's release workflow needs it

The packaging command remains `python3 script/package_source.py`. It creates
`dist/EntitlementDiff-{VERSION}-Source/`, the same versioned `.zip`, and
`EntitlementDiff-{VERSION}-Source.receipt.json`. VERSION continues to come from
Resources/Info.plist, validated as three numeric components. RELOAD_INPUTS.md is
retained along with current validation documentation. This review does not request running it again against an already-packaged
release. Use the new focused tests when adopting the manifest guard;
retain existing packaging test receipts instead of rerunning them by default.

Existing outputs cause refusal, not overwrite. Normal exceptions attempt to remove
outputs created by the invocation. The files are written at their final names;
there is no atomic three-output transaction, durable commit, process lock or
crash-recovery guarantee. A forced termination or cleanup I/O failure may leave
partial outputs. Preserve and inspect them before a deliberate retry. Do not use
a partially written ZIP merely because its final-looking filename exists.

The limited scan checks configured credential markers and personal home paths.
It is not a universal secret detector or a hostile-filesystem isolation boundary.
Review the publication contents before upload. No remote publication is performed
by the packager or authorized by this document.

## 4. Describe distribution truthfully

Source packaging does not run application tests, validate signatures, compile icons
or establish binary/tag correspondence. Current published app assets are separate
from this source artifact; preserve the current README distribution description.
Do not overwrite it with the old source-only release narrative. A development app with ad-hoc signing is
not Developer ID distribution or notarization. Do not imply new minimum-OS or Intel
runtime acceptance from a newer SDK build or an Intel-slice extraction test.
No hosted CI, privileged helper, privacy permission change or new root commit is
required by this review.
