import { runCommand, runCommandWithOutput } from "../../utils/setup-pc-utils";

const windowList = runCommandWithOutput(`osascript <<EOF
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
EOF`);

const teamsWindow = windowList.split("\n").find((line) => {
  const [title, appName] = line.split(" — ");
  if (appName !== "MSTeams") return false;
  const knownWindows = ["Chat", "Calendar", "Activity"];
  if (knownWindows.some((prefix) => title.startsWith(prefix))) return false;
  return true;
});

runCommand(`osascript <<EOF
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
`);
