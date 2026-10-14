#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/EntitlementDiffExamples.XXXXXX")"
trap 'rm -rf -- "$WORK"' EXIT
swiftc -swift-version 6 -parse-as-library Sources/EntitlementDiffCore/*.swift script/GenerateExample.swift -o "$WORK/generate"
"$WORK/generate" "$ROOT/Examples"
echo "Regenerated the two synthetic example reports."
