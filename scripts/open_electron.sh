#!/usr/bin/env bash

# file path (uses home directory)
FILE="$HOME/focus-electron"

# create file if it doesn't exist
[ -f "$FILE" ] || touch "$FILE"

# update mtime to now
touch "$FILE"

echo "mtime updated for: $FILE"
