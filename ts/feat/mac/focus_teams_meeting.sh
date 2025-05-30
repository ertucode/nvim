#!/bin/bash

# Get the list of all visible windows and their application names
windowList=$(osascript <<EOF
set output to ""
tell application "System Events"
    set appList to (every process whose visible is true)
    repeat with proc in appList
        set winList to windows of proc
        repeat with w in winList
            set output to output & (name of w) & " — " & (name of proc) & linefeed
        end repeat
    end repeat
end tell
return output
EOF
)

# Find the desired Teams window
teamsWindow=""
while IFS= read -r line; do
  title="${line%% — *}"
  appName="${line##* — }"

  if [[ "$appName" != "MSTeams" ]]; then
    continue
  fi

  case "$title" in
    Chat*|Calendar*|Activity*)
      continue
      ;;
  esac

  teamsWindow="$title"
  break
done <<< "$windowList"

# If a valid Teams window was found, bring it to the front and raise it
if [[ -n "$teamsWindow" ]]; then
  osascript <<EOF
tell application "System Events"
    tell application process "Microsoft Teams"
        set frontmost to true
        repeat with w in (windows)
            if name of w is "${teamsWindow}" then
                perform action "AXRaise" of w
                exit repeat
            end if
        end repeat
    end tell
end tell
EOF
fi

