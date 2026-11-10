import * as fs from "fs";
import baseKarabiner from "./base-karabiner.json";
import { writeFile } from "../../utils/file-system";
import {
  sharedClipboardImagePath,
  sharedClipboardImageScript,
  sharedClipboardImageScriptPath,
  sharedClipboardManipulators,
  sharedClipboardPath,
  sharedClipboardTypePath,
} from "./shared-clipboard";
import {
  sharedScriptsPath,
  writeRefreshSharedConfigsScript,
  writeSharedFile,
} from "./shared-config";

// https://karabiner-elements.pqrs.org/docs/json/
const sharedKarabinerPath = "/Users/Shared/karabiner.json";
const setupKarabinerScriptPath = `${sharedScriptsPath}/setup-karabiner.sh`;
const refreshSharedConfigsScriptPath =
  "/Users/Shared/scripts/refresh-configs.sh";

const setupKarabinerScript = `#!/bin/sh
set -eu

config_directory="$HOME/.config/karabiner"
destination="$config_directory/karabiner.json"
temporary_file="$destination.$$"
agent_label="codes.ertu.shared-karabiner"
agents_directory="$HOME/Library/LaunchAgents"
agent_path="$agents_directory/$agent_label.plist"

sync_config() {
  if [ -L "$config_directory" ]; then
    if [ "$(/usr/bin/readlink "$config_directory")" = "/Users/Shared/karabiner" ]; then
      /bin/rm "$config_directory"
    fi
  fi

  /bin/mkdir -p "$config_directory"
  trap '/bin/rm -f "$temporary_file"' EXIT
  /bin/cp /Users/Shared/karabiner.json "$temporary_file"
  /bin/chmod 600 "$temporary_file"
  /bin/mv "$temporary_file" "$destination"

  /bin/launchctl kickstart -k "gui/$(/usr/bin/id -u)/org.pqrs.service.agent.karabiner_console_user_server" >/dev/null 2>&1 || true
}

if [ "\${1:-}" = "--sync" ]; then
  sync_config
  exit 0
fi

/bin/mkdir -p "$agents_directory"
temporary_agent="$agent_path.$$"
trap '/bin/rm -f "$temporary_agent"' EXIT
/bin/cat > "$temporary_agent" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>codes.ertu.shared-karabiner</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>/Users/Shared/scripts/setup-karabiner.sh</string>
    <string>--sync</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>ThrottleInterval</key>
  <integer>2</integer>
  <key>WatchPaths</key>
  <array>
    <string>/Users/Shared/karabiner.json</string>
  </array>
</dict>
</plist>
PLIST
/bin/chmod 644 "$temporary_agent"
/bin/mv "$temporary_agent" "$agent_path"

user_domain="gui/$(/usr/bin/id -u)"
/bin/launchctl bootout "$user_domain/$agent_label" >/dev/null 2>&1 || true
/bin/launchctl bootstrap "$user_domain" "$agent_path"
`;

// prettier-ignore
const manipulators = [
    brightness("f1", "decrease", 122),
    brightness("f2", "increase", 120),
    brightness("down_arrow", "decrease", 122),
    brightness("up_arrow", "increase", 120),
    c("a", ["option"                ], "open -a 'Ghostty'"),
    c("w", ["option"                ], "open -a 'Google Chrome' || open -a 'Zen' || open -a 'Firefox'"),
    c("f", ["option"                ], "open '/Applications/Koda.app'"),
    c("t", ["option"                ], "open -a 'Microsoft Teams'"),
    c("o", ["option"                ], "open -a 'Microsoft Outlook'"),
    c("p", ["option"                ], "~/.config/nvim/scripts/open_kova.sh"),
    c("v", ["option"                ], "open -a 'Visual Studio Code'"),
    c("s", ["option"                ], "open -a 'Simulator'"),
    c("b", ["option"                ], "open -a 'IntelliJ IDEA'"),
    c("q", ["option"                ], "open -a 'Mpv'"),
    c("k", ["option"                ], "open -a 'Karabiner-Elements'"),
    c("n", ["option"                ], "~/.config/nvim/scripts/open_chrome_tab.sh 'https://notes.ertu.codes'"),
    c("g", ["option"                ], "open -a 'DataGrip'"),
    c("c", ["option"                ], "open -a 'Whatsapp'"),
    c("r", ["option"                ], "open -a 'Rider'"),
    c("e", ["option"                ], "~/.config/nvim/scripts/open_electron.sh"),
    c("d", ["option"                ], "~/.config/nvim/scripts/open_koda.sh ~/Downloads"),
    c("p", ["option", "left_control"], "open 'raycast://extensions/raycast/clipboard-history/clipboard-history'",),
    c("l", ["option", "left_control"], "open -a 'Lens'"),
    c("d", ["option", "left_control"], "open -a 'Docker Desktop'"),
    c("s", ["option", "left_control"], "open -a 'Slack'"),
    c("o", ["option", "left_control"], "open -a 'Obs'"),
    c("v", ["option", "left_control"], "open -a 'FortiClient'"),
    c("q", ["option", "left_control"], "open -a 'qBittorrent'"),
    c("w", ["option", "left_control"], "open -a 'Firefox'",),
    c("i", ["option", "left_control"], "~/.config/nvim/scripts/open_kopa.sh"),
    c("c", ["option", "left_control"], "open -a 'Calendar'"),
    c("k", ["option", "left_control"], "~/.config/nvim/scripts/open_ghostty_command.sh 'cd ~/dev/myscripts && /opt/homebrew/bin/bun run scripts/kill-processes.ts'"),
    c("t", ["option", "left_control"], "~/.config/nvim/scripts/open_ghostty_command.sh 'cd ~/dev/myscripts && /opt/homebrew/bin/bun run scripts/tmux-kill-sessions.ts -on'"),
    c("4", ["option", "left_control"], "~/.config/nvim/scripts/open_ghostty_command.sh 'cd ~/dev/myscripts && /opt/homebrew/bin/bun run scripts/tmux-kill-sessions.ts'"),
    ...sharedClipboardManipulators,
    c("k", ["command", "shift", "control"], `/bin/sh ${refreshSharedConfigsScriptPath}`),
  ];

function brightness(
  key: "f1" | "f2" | "down_arrow" | "up_arrow",
  action: "decrease" | "increase",
  systemKeyCode: 122 | 120,
) {
  const openDimmer = `/usr/bin/open -g 'macos-dimmer://start-${action}' 2>/dev/null`;
  const changeSystemBrightness = `/usr/bin/osascript -e 'tell application "System Events" to key code ${systemKeyCode} using {option down, shift down}'`;

  return {
    from: {
      key_code: key,
      modifiers: { mandatory: ["fn"] },
    },
    to: [{ shell_command: `${openDimmer} || ${changeSystemBrightness}` }],
    to_after_key_up: [
      {
        shell_command:
          "/usr/bin/open -g 'macos-dimmer://stop' >/dev/null 2>&1 || :",
      },
    ],
    type: "basic",
  } as const;
}

function c(key: string, mandatory: string[], command: string) {
  return {
    from: {
      key_code: key,
      modifiers: { mandatory: mandatory },
    },
    to: [{ shell_command: command }],
    type: "basic",
  } as const;
}

export function createKarabiner() {
  const base = JSON.parse(JSON.stringify(baseKarabiner));
  base.profiles[0].complex_modifications.rules[0].manipulators = manipulators;

  return base;
}

function ensureSharedClipboardFile(path: string, initialContent = "") {
  const file = fs.openSync(path, "a", 0o666);
  fs.closeSync(file);

  if (initialContent && fs.statSync(path).size === 0) {
    fs.writeFileSync(path, initialContent);
  }

  const fileMode = fs.statSync(path).mode & 0o666;
  if (fileMode !== 0o666) {
    fs.chmodSync(path, 0o666);
  }
}

export function setupKarabiner() {
  const karabinerJson = JSON.stringify(createKarabiner());

  writeFile("~/.config/nvim/dotfiles/karabiner/karabiner.json", karabinerJson);
  fs.mkdirSync(sharedScriptsPath, { recursive: true, mode: 0o755 });
  ensureSharedClipboardFile(sharedClipboardPath);
  ensureSharedClipboardFile(sharedClipboardImagePath);
  ensureSharedClipboardFile(sharedClipboardTypePath, "text");
  writeSharedFile(
    sharedClipboardImageScriptPath,
    sharedClipboardImageScript,
    0o644,
  );
  writeSharedFile(sharedKarabinerPath, karabinerJson, 0o666);
  writeSharedFile(setupKarabinerScriptPath, setupKarabinerScript, 0o755);
  writeRefreshSharedConfigsScript();
}

if (import.meta.main) {
  setupKarabiner();
}
