#!/bin/env bash

rm -rf ~/Library/Application\ Support/Lens
rm -rf ~/Library/Application\ Support/OpenLens

# Preferences
rm -f ~/Library/Preferences/com.electron.lens.plist
rm -f ~/Library/Preferences/com.electron.openlens.plist

# Saved application state
rm -rf ~/Library/Saved\ Application\ State/com.electron.lens.savedState
rm -rf ~/Library/Saved\ Application\ State/com.electron.openlens.savedState

# Cache
rm -rf ~/Library/Caches/Lens
rm -rf ~/Library/Caches/OpenLens

# Logs
rm -rf ~/Library/Logs/Lens
rm -rf ~/Library/Logs/OpenLens
