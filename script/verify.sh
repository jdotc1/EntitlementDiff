#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
swift --version
swift test -Xswiftc -warnings-as-errors
swift test --configuration release -Xswiftc -warnings-as-errors
for script in script/*.sh; do bash -n "$script"; done
if [[ "$(uname -s)" == Darwin ]]; then
  ./script/build_and_run.sh --build-only
  /usr/bin/codesign --verify --strict --verbose=2 "$ROOT/dist/EntitlementDiff.app"
  echo "Native compile, integration tests, bundle staging and development signature verification completed."
  echo "Continue with docs/MACOS_ACCEPTANCE.md; no visual or accessibility checks were implied."
else
  ./script/typecheck_observation.sh
  swiftc -frontend -parse -target arm64-apple-macosx14.0 Sources/EntitlementDiffSecurity/*.swift Tests/EntitlementDiffSecurityTests/*.swift
  swiftc -frontend -parse -target arm64-apple-macosx14.0 Sources/EntitlementDiffApp/App/*.swift Sources/EntitlementDiffApp/Views/*.swift Sources/EntitlementDiffApp/Support/*.swift
  echo "Portable tests and native-source syntax parsing completed."
  echo "Security.framework, SwiftUI, AppKit, macOS Observation, app launch and native integration were NOT validated."
fi
