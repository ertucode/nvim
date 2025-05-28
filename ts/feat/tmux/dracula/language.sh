#!/usr/bin/env bash

language=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist  AppleSelectedInputSources | egrep -w 'KeyboardLayout Name' | sed -E 's/.+ = "?([^"]+)"?;/\1/')

if [ "$language" = "ABC" ]; then
  echo "ABC"
else
  echo "TR"
fi
sleep 1
