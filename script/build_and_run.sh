#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
case "$MODE" in run|--build-only|--verify|--debug|--logs|--telemetry) ;; *)
  echo "Usage: $0 [--build-only|--verify|--debug|--logs|--telemetry]" >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { echo "Only one mode is accepted." >&2; exit 2; }
[[ "$(uname -s)" == Darwin ]] || { echo "The SwiftUI app requires macOS. Run ./script/verify.sh for portable checks." >&2; exit 2; }
CONFIGURATION="${CONFIGURATION:-debug}"
case "$CONFIGURATION" in debug|release) ;; *) echo "CONFIGURATION must be debug or release." >&2; exit 2 ;; esac
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
APP_NAME="EntitlementDiff"
DIST="$ROOT/dist"
BUNDLE="$DIST/$APP_NAME.app"
APP_BINARY="$BUNDLE/Contents/MacOS/$APP_NAME"
[[ ! -L "$DIST" && ! -L "$BUNDLE" ]] || { echo "Refusing a symlinked staging directory/bundle." >&2; exit 1; }

# Stop only this checkout's staged executable, not every similarly named app.
stop_local_app() {
  local pid command i
  for pid in $(/usr/bin/pgrep -x "$APP_NAME" || true); do
    command="$(/bin/ps -p "$pid" -o comm= || true)"
    if [[ "$command" == "$APP_BINARY" ]]; then
      kill -TERM "$pid" 2>/dev/null || true
      for i in {1..30}; do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.1
      done
      if kill -0 "$pid" 2>/dev/null; then
        echo "The local app did not exit. Close it before rebuilding." >&2
        exit 1
      fi
    fi
  done
}
stop_local_app
swift build --configuration "$CONFIGURATION" --product "$APP_NAME"
BUILD_DIR="$(swift build --configuration "$CONFIGURATION" --show-bin-path)"
[[ -f "$BUILD_DIR/$APP_NAME" ]] || { echo "Built executable not found." >&2; exit 1; }
mkdir -p "$DIST"
# This path is fixed under this checkout, checked above, and never an input app.
rm -rf -- "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
cp "$BUILD_DIR/$APP_NAME" "$APP_BINARY"
chmod 755 "$APP_BINARY"
cp "$ROOT/Resources/Info.plist" "$BUNDLE/Contents/Info.plist"
mkdir -p "$BUNDLE/Contents/Resources"
cp "$ROOT/Resources/Icon/Compiled/Assets.car" "$BUNDLE/Contents/Resources/Assets.car"
cp "$ROOT/Resources/Icon/Compiled/EntitlementDiff.icns" "$BUNDLE/Contents/Resources/EntitlementDiff.icns"
/usr/bin/plutil -lint "$BUNDLE/Contents/Info.plist"
# Development-only ad-hoc signing. No identities, keychain changes or notarization.
/usr/bin/codesign --force --sign - "$BUNDLE"

case "$MODE" in
  --build-only) printf 'Staged development bundle: %s\n' "$BUNDLE" ;;
  --debug) /usr/bin/lldb -- "$APP_BINARY" ;;
  --logs|--telemetry)
    /usr/bin/open -n "$BUNDLE"
    # No entitlement values or paths are logged by the application.
    /usr/bin/log stream --info --style compact --predicate 'process == "EntitlementDiff"'
    ;;
  --verify)
    /usr/bin/open -n "$BUNDLE"
    found=0
    for attempt in {1..30}; do
      for pid in $(/usr/bin/pgrep -x "$APP_NAME" || true); do
        if [[ "$(/bin/ps -p "$pid" -o comm= || true)" == "$APP_BINARY" ]]; then found=1; break; fi
      done
      [[ "$found" == 1 ]] && break
      sleep 0.1
    done
    [[ "$found" == 1 ]] || { echo "The staged process was not observed after launch." >&2; exit 1; }
    echo "Staged process observed. This does not verify the UI or inspection behavior."
    ;;
  run) /usr/bin/open -n "$BUNDLE" ;;
esac
