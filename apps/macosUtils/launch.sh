#!/bin/sh
set -eu

app="$HOME/Applications/macOS Utils.app"

# An existing GUI receives routes over its socket. This short-lived process
# must never initialize AppKit/CoreLocation when there is no running GUI.
if "$app/Contents/MacOS/macos-utils" --dispatch "$@"; then
  exit 0
fi

# LaunchServices gives cold starts the same privacy identity as Finder/open.
exec /usr/bin/open -a "$app" --args "$@"
