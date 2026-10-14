# Source publication

The source release contains SwiftPM sources/tests, examples, license, selected
technical documentation, editable/compiled icon resources and local build tools.
Run `python3 script/package_source.py` to create an allowlisted source tree and ZIP
under dist/ using the Info.plist version in each source tree/ZIP name. Existing outputs are preserved; packaging refuses to overwrite them.
The staging scan detects configured credential markers and personal home paths,
including in compiled icon resources. It is not a universal secret detector.

Raw evidence, screenshots, personal agent instructions, historical handoff ZIPs,
workstation build logs and local Git history are excluded. README and the generated
RELEASE_VALIDATION summary distinguish accepted baseline and later focused evidence.
No old checks are rerun by packaging. The normal app build reuses compiled icon
resources; no icon compilation, dependency install or signing identity is needed.

Publish the staged tree with only sanitized publication history as its parent,
never the private local development history. Push only that publication branch.
A downloadable app release requires the separate Developer ID, Apple notarization,
stapling and distribution acceptance workflow. Keep source and app version/build
aligned. Never bypass protections to run a downloaded build.

Current source staging receipts are versioned under evidence/ and excluded from
the publication payload.
