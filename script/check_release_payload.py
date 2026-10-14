#!/usr/bin/env python3
"""Reject selected private markers in a newly staged distributable app payload."""
from pathlib import Path
import re
import sys

app = Path(sys.argv[1])
patterns = {
    "personal home path": rb"/(?:Users|home)/[A-Za-z0-9_.-]+/",
    "private key": rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
    "GitHub token": rb"gh[pousr]_[A-Za-z0-9]{30,}",
}
findings = []
for path in sorted(app.rglob("*")):
    if path.is_symlink():
        findings.append(f"{path.relative_to(app)}: unexpected symlink")
    elif path.is_file():
        data = path.read_bytes()
        for name, pattern in patterns.items():
            if re.search(pattern, data):
                findings.append(f"{path.relative_to(app)}: {name}")
if not (app / "Contents/MacOS/EntitlementDiff").is_file():
    findings.append("main executable missing")
if findings:
    print("Release payload rejected:\n" + "\n".join(findings))
    raise SystemExit(1)
print("New release payload: no configured personal-path/credential markers; not a universal secret detector.")
