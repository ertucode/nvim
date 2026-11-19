#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
app="$HOME/Applications/macOS Utils.app"
executable="$app/Contents/MacOS/macos-utils"

cd "$root"
cargo build --release

if pgrep -f "^$executable( |$)" >/dev/null 2>&1; then
  osascript -e 'tell application id "codes.ertu.macosUtils" to quit' >/dev/null 2>&1 || true
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
ln -sfn "$executable" "$HOME/.local/bin/macos-utils"

codesign --force --deep --sign - "$app"
touch "$app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$app" >/dev/null 2>&1
open "$app"
