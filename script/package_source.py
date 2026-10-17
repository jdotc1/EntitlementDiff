#!/usr/bin/env python3
"""Package the public working tree; preserve documentation and validation evidence verbatim."""
from pathlib import Path
import json
import plistlib
import re
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parent.parent
DIST = ROOT / "dist"
DOCS = {
    "docs/DESIGN.md", "docs/REPORT_FORMAT.md", "docs/report.schema.json",
    "docs/SOURCES.md", "docs/PUBLISHING.md", "docs/RELEASE_VALIDATION.md",
    "docs/MACOS_ACCEPTANCE.md", "docs/RELOAD_INPUTS.md",
    "docs/SHARED_COMPARISON.md", "docs/FOCUSED_VALUE.md", "docs/BRANCH_NAVIGATION.md",
    "docs/COMPARISON_BROWSER.md", "docs/SAVED_BASELINE.md", "docs/SAVED_COMPARISON.md", "docs/EXACT_FIND.md", "docs/COPY_EXACT_KEY.md", "docs/COMPARISON_GUIDANCE.md", "docs/INSPECTOR_PROJECTION_REUSE.md",
}
ROOT_FILES = {"Package.swift", "LICENSE", "README.md", ".gitignore", ".gitattributes"}
REQUIRED = ROOT_FILES | {"docs/PUBLISHING.md", "docs/RELEASE_VALIDATION.md", "docs/MACOS_ACCEPTANCE.md", "docs/RELOAD_INPUTS.md",
    "docs/SHARED_COMPARISON.md", "docs/FOCUSED_VALUE.md", "docs/BRANCH_NAVIGATION.md",
    "docs/COMPARISON_BROWSER.md", "docs/SAVED_BASELINE.md", "docs/SAVED_COMPARISON.md", "docs/EXACT_FIND.md", "docs/COPY_EXACT_KEY.md", "docs/COMPARISON_GUIDANCE.md", "docs/INSPECTOR_PROJECTION_REUSE.md", "Resources/Info.plist", "script/package_source.py"}
PATTERNS = {
    "private key": rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
    "GitHub token": rb"gh[pousr]_[A-Za-z0-9]{30,}",
    "AWS access key": rb"AKIA[A-Z0-9]{16}",
    "personal home path": rb"/(?:Users|home)/[A-Za-z0-9_.-]+/",
}


def publishable(name):
    return (name in ROOT_FILES or name in DOCS
            or name.startswith(("Sources/", "Tests/", "Examples/", "script/"))
            or (name.startswith("Resources/") and not name.endswith(".log")))


def selected_index_paths():
    """Use index metadata to reject unresolved or non-regular selected entries.

    Contents still come from the working tree, not the indexed blob objects.
    """
    entries = subprocess.check_output(
        ["git", "ls-files", "--stage", "-z"], cwd=ROOT
    ).decode("utf-8").split("\0")
    names = set()
    for entry in entries:
        if not entry:
            continue
        metadata, name = entry.split("\t", 1)
        mode, _object_id, stage = metadata.split()
        if not publishable(name):
            continue
        if stage != "0":
            raise SystemExit(f"Refusing unresolved release input: {name}")
        if mode not in {"100644", "100755"}:
            raise SystemExit(f"Refusing non-regular indexed release input: {name} (mode {mode})")
        names.add(name)
    return sorted(names)


def source_version():
    with (ROOT / "Resources/Info.plist").open("rb") as metadata_file:
        version = plistlib.load(metadata_file)["CFBundleShortVersionString"]
    if not isinstance(version, str) or not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise SystemExit("Invalid source release version")
    return version


def main():
    version = source_version()
    DEST = DIST / f"EntitlementDiff-{version}-Source"
    ARCHIVE = DIST / f"EntitlementDiff-{version}-Source.zip"
    RECEIPT = DIST / f"EntitlementDiff-{version}-Source.receipt.json"
    if DIST.is_symlink():
        raise SystemExit("Refusing a symlinked distribution directory.")
    if any(path.exists() or path.is_symlink() for path in (DEST, ARCHIVE, RECEIPT)):
        raise SystemExit("Source staging output already exists; preserve or move it before packaging again.")
    names = selected_index_paths()
    missing = REQUIRED - set(names)
    if missing:
        raise SystemExit("Missing tracked release inputs: " + ", ".join(sorted(missing)))
    for name in names:
        source = ROOT / name
        if (source.is_symlink() or not source.is_file()
                or not source.resolve().is_relative_to(ROOT)
                or any(parent.is_symlink() for parent in source.parents if parent != ROOT and ROOT in parent.parents)):
            raise SystemExit(f"Refusing non-regular release input: {name}")

    # This is a local, single-invocation packaging tool, not a concurrent or
    # hostile-filesystem boundary. Only outputs created by this invocation are removed.
    DEST.mkdir(parents=True)
    archive_created = False
    receipt_created = False
    try:
        for name in names:
            target = DEST / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, target)
        findings = []
        for name in names:
            data = (DEST / name).read_bytes()
            for label, pattern in PATTERNS.items():
                if re.search(pattern, data):
                    findings.append({"file": name, "finding": label})
        if findings:
            raise SystemExit("Publication scan found disallowed content: " + json.dumps(findings))
        with zipfile.ZipFile(ARCHIVE, "x", compression=zipfile.ZIP_DEFLATED) as archive:
            archive_created = True
            for name in names:
                archive.write(DEST / name, "EntitlementDiff/" + name)
        receipt = {
            "file_count": len(names),
            "version": version,
            "source_selection": "Tracked working-tree files; not a commit or binary attestation.",
            "selection_policy": "Explicit root/document allowlists and source/test/example/script/resource prefixes; manually review all selected files.",
            "excluded_roots": ["evidence/", ".git/", "dist/"],
            "scan": "No matches for configured credential markers or personal home paths; not a universal secret detector.",
            "validation": "Documentation copied unchanged. Packaging did not run tests or verify signing.",
        }
        with RECEIPT.open("x", encoding="utf-8") as handle:
            receipt_created = True
            handle.write(json.dumps(receipt, indent=2) + "\n")
    except BaseException:
        if receipt_created:
            RECEIPT.unlink(missing_ok=True)
        if archive_created:
            ARCHIVE.unlink(missing_ok=True)
        shutil.rmtree(DEST)
        raise
    print(f"Prepared {len(names)} source files in {DEST.relative_to(ROOT)} and {ARCHIVE.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
