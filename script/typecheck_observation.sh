#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
if [[ "$(uname -s)" == Darwin ]]; then
  swift build --target EntitlementDiffModel -Xswiftc -warnings-as-errors
  exit
fi
swift build --target EntitlementDiffCore -Xswiftc -warnings-as-errors
TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT
# Enable precisely the model's macOS Observation annotations in scratch copies.
# This tests macro expansion and actor checking, not any Apple platform APIs.
for file in Sources/EntitlementDiffModel/*.swift; do
  sed 's/#if os(macOS)/#if true/g' "$file" > "$TEMP/$(basename "$file")"
done
swiftc -typecheck -swift-version 6 -warnings-as-errors \
  -I "$(swift build --show-bin-path)/Modules" "$TEMP"/*.swift
echo "Observation-enabled model typechecked. Native linking/runtime not tested."
