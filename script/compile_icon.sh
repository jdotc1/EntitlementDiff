#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
# Explicit authoring action: run only after changing the native Icon Composer document.
# Ordinary app builds reuse the checked-in compiled icon resources.
mkdir -p Resources/Icon/Compiled
xcrun actool Resources/Icon/EntitlementDiff.icon \
  --compile Resources/Icon/Compiled --output-format human-readable-text \
  --app-icon EntitlementDiff --include-all-app-icons --target-device mac \
  --platform macosx --minimum-deployment-target 14.0 \
  --output-partial-info-plist Resources/Icon/Compiled/partial-info.plist
