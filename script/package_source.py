#!/usr/bin/env python3
"""Stage an allowlisted source release without local evidence or historical archives."""
from pathlib import Path
import json
import plistlib
import re
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parent.parent
with (ROOT / "Resources/Info.plist").open("rb") as metadata_file:
    VERSION = plistlib.load(metadata_file)["CFBundleShortVersionString"]
if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", VERSION):
    raise SystemExit("Invalid source release version")
DEST = ROOT / "dist" / f"EntitlementDiff-{VERSION}-Source"
ARCHIVE = ROOT / "dist" / f"EntitlementDiff-{VERSION}-Source.zip"
DOCS = {
    "docs/DESIGN.md", "docs/REPORT_FORMAT.md", "docs/report.schema.json",
    "docs/SOURCES.md", "docs/PUBLISHING.md", "docs/RELOAD_INPUTS.md",
}
ROOT_FILES = {"Package.swift", "LICENSE", "README.md", ".gitignore", ".gitattributes"}


def publishable(name):
    return (name in ROOT_FILES or name in DOCS
            or name.startswith(("Sources/", "Tests/", "Examples/", "script/"))
            or (name.startswith("Resources/") and not name.endswith(".log")))


def main():
    if DEST.exists() or ARCHIVE.exists():
        raise SystemExit("Source staging output already exists; preserve or move it before packaging again.")
    files = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
    names = sorted(name for name in files if name and publishable(name))
    # Include this newly authored packaging tool before its first local commit.
    names = sorted(set(names) | {"script/package_source.py", "docs/PUBLISHING.md"})
    for name in names:
        source = ROOT / name
        if source.is_symlink() or not source.is_file():
            raise SystemExit(f"Refusing non-regular release input: {name}")
    DEST.mkdir(parents=True)
    for name in names:
        target = DEST / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, target)
    readme = DEST / "README.md"
    text = readme.read_text()
    start = text.index("## Current local validation")
    text = text[:start] + """## Input Identity and Build Metadata

Source panes show version/build. Input Details separates bundle and signing
identifiers and shows the selected location, with Reveal in Finder. Optional fields
are bounded and unverified. Locations stay session-only; report schema 1 and
export bytes are unchanged.

## Validation and distribution

This source release reuses accepted local validation receipts. The baseline passed
58 tests in both debug and release, including all eight native integration tests.
Subsequent browser, drop, structured-inspector, inspector-navigation and Reload/Retry changes
passed focused checks and actual local app inspection. Input Identity and Build Metadata passed six new focused methods and native
selection, details, Finder reveal, reload and Swap inspection. The latest affected
checks preserve report schema 1 and unchanged report bytes. These are separate receipts, not a fresh full-suite run
on the release snapshot. See `docs/RELEASE_VALIDATION.md` for evidence boundaries.

Build locally using the commands above. This release does not include an installed
app binary. Local builds are ad-hoc development signed, not Developer ID signed or
notarized. No distribution readiness or complete accessibility acceptance is claimed.
`LICENSE` is MIT.
"""
    text = text.replace("The Codex **Run** action calls the same script.", "")
    text += f"\nNotarized arm64 app downloads and source releases: https://github.com/jdotc1/EntitlementDiff/releases/tag/v{VERSION}\n"
    readme.write_text(text)
    icon_readme = DEST / "Resources/Icon/README.md"
    text = icon_readme.read_text()
    text = text.replace("Evidence: compile.log, build.log and docs/ICON_ACCEPTANCE.md. This is local\nintegration, not distribution signing, publication or cross-device file delivery.",
                        "The checked-in resources were built and locally inspected. Raw workstation logs\nare excluded from source releases. This is not distribution-signing evidence.")
    icon_readme.write_text(text)
    (DEST / "docs/RELEASE_VALIDATION.md").write_text("""# Accepted local validation summary

- Original macOS baseline: 58 tests in debug and 58 in release, including eight
  native integration methods. Native compilation and local development signature
  verification passed on Apple silicon, macOS 27.2 beta, Apple Swift 6.4.
- Comparison browser: three new focused methods passed and local UI inspected.
- Application drop: six new focused policy/action methods passed. Real Finder
  drops into both panes, explicit architecture rejection and invalid-file recovery
  were observed. Native multiple-file gesture and held-hover outline were not
  separately accepted; multiple-input rejection has focused test coverage.
- Structured inspector: three focused methods passed and local UI inspected.
- Reload/Retry: five new focused methods passed; changed-fixture reload, failed
  input recovery and Reload Both were inspected in the actual development app.
- Input identity: six new focused methods passed, including native metadata refresh,
  bounds/type checks, unchanged report bytes/schema and stale-result continuity.
  Same-named inputs, Finder reveal, changed/malformed metadata reload and Swap
  were inspected in the actual development app.
- Inspector navigation: six affected methods passed (three new, three existing),
  and rebuilt app search, paging, filtering and complete filtered JSON copy were
  inspected. No full-suite rerun occurred after the baseline.

Raw workstation logs, screenshots, handoff archives, personal agent instructions
and local Git history are excluded. The local audit retains those accepted receipts.
This summary is not a new test run, independent release audit or binary-distribution
qualification. Accessibility work was explicitly stopped; complete acceptance is
not claimed. AppKit sharing-indicator geometry faults were previously localized to
system stacks; no product fix or fault-free-runtime claim follows.
""")
    design = DEST / "docs/DESIGN.md"
    text = design.read_text().replace("RED_TEAM_REVIEW.md", "RELEASE_VALIDATION.md").replace("INSPECTOR_NAVIGATION.md", "RELEASE_VALIDATION.md").replace("INPUT_IDENTITY.md", "RELEASE_VALIDATION.md")
    design.write_text(text)
    (DEST / ".gitattributes").write_text("* text=auto\n*.png binary\n*.car binary\n*.icns binary\n")
    patterns = {
        "private key": rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
        "GitHub token": rb"gh[pousr]_[A-Za-z0-9]{30,}",
        "AWS access key": rb"AKIA[A-Z0-9]{16}",
        "personal home path": rb"/(?:Users|home)/[A-Za-z0-9_.-]+/",
    }
    staged = sorted(p for p in DEST.rglob("*") if p.is_file())
    findings = []
    for path in staged:
        data = path.read_bytes()
        for label, pattern in patterns.items():
            if re.search(pattern, data):
                findings.append({"file": str(path.relative_to(DEST)), "finding": label})
    if findings:
        raise SystemExit("Publication scan found disallowed content: " + json.dumps(findings))
    with zipfile.ZipFile(ARCHIVE, "x", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in staged:
            archive.write(path, "EntitlementDiff/" + path.relative_to(DEST).as_posix())
    receipt = {"file_count": len(staged), "excluded": ["evidence/", "local Git history", "historical archives", "personal instructions", "workstation logs"],
               "scan": "No matches for configured credential markers or personal home paths; not a universal secret detector.",
               "validation": "Accepted build/test/runtime receipts reused; no tests, hashes or signing verification repeated."}
    (ROOT / f"evidence/112-v{VERSION}-source-preparation.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(f"Prepared {len(staged)} source files in {DEST.relative_to(ROOT)} and {ARCHIVE.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
