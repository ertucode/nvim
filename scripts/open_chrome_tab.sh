#!/bin/zsh

url="$1"

osascript - "$url" <<'APPLESCRIPT'
on run argv
  set targetURL to item 1 of argv

  tell application "Google Chrome"
    activate

    repeat with chromeWindow in windows
      set tabIndex to 0
      repeat with chromeTab in tabs of chromeWindow
        set tabIndex to tabIndex + 1
        if URL of chromeTab starts with targetURL then
          set active tab index of chromeWindow to tabIndex
          set index of chromeWindow to 1
          return
        end if
      end repeat
    end repeat

    if (count of windows) is 0 then
      make new window
      set URL of active tab of window 1 to targetURL
    else
      tell window 1 to make new tab with properties {URL:targetURL}
    end if
  end tell
end run
APPLESCRIPT
