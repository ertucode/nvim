#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
app="$HOME/Applications/macOS Utils.app"
executable="$app/Contents/MacOS/macos-utils"
signing_identity=${MACOS_UTILS_SIGNING_IDENTITY:-macOS Utils Local Signing}

# Check before replacing the installed executable.
if ! security find-certificate -c "$signing_identity" >/dev/null 2>&1; then
  echo "Code-signing identity '$signing_identity' is not installed." >&2
  echo "Create a local Code Signing certificate or set MACOS_UTILS_SIGNING_IDENTITY." >&2
  exit 1
fi

cd "$root"
/bin/sh ./install-wifi-helper.sh
cargo build --release --bin macos-utils

if pgrep -f "^$executable( |$)" >/dev/null 2>&1; then
  # Quit over our own socket: no Apple Events/Automation permission is needed.
  "$executable" --dispatch quit >/dev/null 2>&1 || true
  attempts=0
  while pgrep -f "^$executable( |$)" >/dev/null 2>&1 && [ "$attempts" -lt 50 ]; do
    sleep 0.1
    attempts=$((attempts + 1))
  done
fi

if pgrep -f "^$executable( |$)" >/dev/null 2>&1; then
  echo "macOS Utils is still running; quit it and run install.sh again." >&2
  exit 1
fi

mkdir -p "$app/Contents/MacOS" "$HOME/.local/bin"
cp Info.plist "$app/Contents/Info.plist"
cp target/release/macos-utils "$executable"

# A persistent identity keeps the app's designated requirement stable across
# builds, so Location Services and Keychain grants survive reinstalls.
codesign --force --deep --sign "$signing_identity" \
  --entitlements Entitlements.plist \
  "$app"
touch "$app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$app" >/dev/null 2>&1
# Do not launch the GUI binary from Karabiner's shell: Location Services may
# attribute that process to the launcher rather than this application bundle.
# Rename over the old symlink instead of writing through it into the signed app.
cp launch.sh "$HOME/.local/bin/macos-utils.new"
chmod 755 "$HOME/.local/bin/macos-utils.new"
mv -f "$HOME/.local/bin/macos-utils.new" "$HOME/.local/bin/macos-utils"
open "$app"
