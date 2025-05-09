#!/bin/bash

# Get all visible window titles and app names
window_list=$(osascript <<EOF
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

# Find the first Microsoft Teams window that doesn't match excluded prefixes
target_window_title=$(echo "$window_list" | awk -F' — ' '
$2 == "Microsoft Teams" &&
$1 !~ /^Chat \|/ &&
$1 !~ /^Calendar \|/ &&
$1 !~ /^Activity \|/ {
    print $1
    exit
}')

# If a matching window was found, use AppleScript to bring it to the front
if [ -n "$target_window_title" ]; then
    osascript <<EOF
tell application "System Events"
    tell application process "Microsoft Teams"
        set frontmost to true
        repeat with w in (windows)
            if name of w is "$target_window_title" then
                perform action "AXRaise" of w
                exit repeat
            end if
        end repeat
    end tell
end tell
EOF
else
    echo "No matching Teams meeting window found."
fi

