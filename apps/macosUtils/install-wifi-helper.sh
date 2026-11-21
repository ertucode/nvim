#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
directory="$HOME/Library/Application Support/macOS Utils"
helper="$directory/wifi-keychain"

if [ -e "$helper" ]; then
  # Even re-signing this helper can change its Keychain partition. Never touch
  # it on normal installs, including when its source or signing identity changes.
  codesign --verify --strict "$helper"
  echo "Keeping the existing Wi-Fi helper unchanged."
  exit 0
fi

identity=${MACOS_UTILS_SIGNING_IDENTITY:-macOS Utils Local Signing}
cd "$root"
cargo build --release --bin wifi-keychain
mkdir -p "$directory"
chmod 700 "$directory"
temporary="$directory/wifi-keychain.$$"
trap 'rm -f "$temporary"' EXIT
cp target/release/wifi-keychain "$temporary"
chmod 700 "$temporary"
codesign --sign "$identity" --identifier codes.ertu.macosUtils.wifi-keychain "$temporary"
# Fail safely if concurrent installers raced, rather than replacing an owner
# that might already have created Keychain entries.
if ! ln "$temporary" "$helper" 2>/dev/null; then
  codesign --verify --strict "$helper"
fi
echo "Installed the stable Wi-Fi helper (future GUI builds will keep it)."
