# Source publication

The source release contains SwiftPM sources/tests, examples, license, selected
technical documentation, editable/compiled icon resources and local build tools.
Run `python3 script/package_source.py` to create an allowlisted source tree and ZIP
under dist/. Existing outputs are preserved; packaging refuses to overwrite them.
The staging scan detects configured credential markers and personal home paths,
including in compiled icon resources. It is not a universal secret detector.

Raw evidence, screenshots, personal agent instructions, historical handoff ZIPs,
workstation build logs and local Git history are excluded. README and the generated
RELEASE_VALIDATION summary distinguish accepted baseline and later focused evidence.
No old checks are rerun by packaging. The normal app build reuses compiled icon
resources; no icon compilation, dependency install or signing identity is needed.

Publish the staged tree from a clean root commit, not the local development history.
Confirm the destination repository and visibility before creating it. Push only
the sanitized publication branch. Create a source-only release with the prepared
ZIP and state the development-signature/distribution limitations explicitly.
Do not upload dist/EntitlementDiff.app as a notarized/Developer ID product: no such
qualification is established. Never bypass protections to run a downloaded build.
