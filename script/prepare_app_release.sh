#!/usr/bin/env bash
# Stage a new release candidate. Does not sign, notarize, verify, launch, or publish.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
[[ $# == 0 ]] || { echo "Usage: $0" >&2; exit 2; }
[[ "$(uname -s)" == Darwin ]] || { echo "macOS developer tools required." >&2; exit 1; }
cd "$ROOT"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Resources/Info.plist)"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$BUILD" =~ ^[0-9]+$ ]] || { echo "Invalid release version/build." >&2; exit 1; }
STAGE="$ROOT/dist/app-release-$VERSION-$BUILD-arm64"
[[ ! -L "$ROOT/dist" && ! -e "$STAGE" && ! -L "$STAGE" ]] || { echo "Unsafe or existing release output; preserve it before preparing another candidate." >&2; exit 1; }
# Different optimization/architecture/path-mapping inputs from accepted development builds.
swift build -c release --arch arm64 --product EntitlementDiff \
  -Xswiftc -debug-prefix-map -Xswiftc "$ROOT=."
swift build -c release --arch arm64 --product entitlementdiff-cli \
  -Xswiftc -debug-prefix-map -Xswiftc "$ROOT=."
BIN_DIR="$(swift build -c release --arch arm64 --show-bin-path)"
APP="$STAGE/EntitlementDiff.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp -X "$BIN_DIR/EntitlementDiff" "$APP/Contents/MacOS/EntitlementDiff"
cp -X "$BIN_DIR/entitlementdiff-cli" "$APP/Contents/MacOS/entitlementdiff-cli"
/usr/bin/strip -S -x "$APP/Contents/MacOS/entitlementdiff-cli"
chmod 755 "$APP/Contents/MacOS/entitlementdiff-cli"
# Strip debug and local symbol records from the staged copy only.
/usr/bin/strip -S -x "$APP/Contents/MacOS/EntitlementDiff"
chmod 755 "$APP/Contents/MacOS/EntitlementDiff"
cp -X Resources/Info.plist "$APP/Contents/Info.plist"
cp -X Resources/Icon/Compiled/Assets.car "$APP/Contents/Resources/Assets.car"
cp -X Resources/Icon/Compiled/EntitlementDiff.icns "$APP/Contents/Resources/EntitlementDiff.icns"
python3 script/check_release_payload.py "$APP"
cat > "$STAGE/READINESS.txt" <<'NOTICE'
RELEASE CANDIDATE ONLY — NOT FOR DOWNLOAD PUBLICATION
Apple silicon arm64. macOS 14+. Release optimization; mapped Swift debug paths.
No Developer ID signing, secure timestamp, hardened-runtime signing, notarization,
stapling, final distribution verification, or downloaded-app acceptance performed.
Linker-generated ad-hoc code signatures may be present; they are not Developer ID.
Use docs/APP_RELEASE.md for the remaining explicit distribution steps.
NOTICE
printf 'Staged candidate: %s\nNo signing, notarization, verification, launch or upload performed.\n' "$STAGE"
