import baseKarabiner from "./base-karabiner.json";

// https://karabiner-elements.pqrs.org/docs/json/
// prettier-ignore
const manipulators = [
    c("a", ["option"                ], "open -a 'Alacritty'"),
    c("w", ["option"                ], "open -a 'Zen'"),
    c("f", ["option"                ], "open -a 'Finder'"),
    c("t", ["option"                ], "open -a 'Microsoft Teams'"),
    c("o", ["option"                ], "open -a 'Microsoft Outlook'"),
    c("p", ["option"                ], "open -a 'Postman'"),
    c("v", ["option"                ], "open -a 'Visual Studio Code'"),
    c("s", ["option"                ], "open -a 'Simulator'"),
    c("b", ["option"                ], "open -a 'IntelliJ IDEA'"),
    c("e", ["option"                ], "open -a 'qemu-system-aarch64'"),
    c("q", ["option"                ], "open -a 'IINA'"),
    c("k", ["option"                ], "open -a 'Karabiner-Elements'"),
    c("n", ["option"                ], "open -a 'Obsidian'"),
    c("g", ["option"                ], "open -a 'DataGrip'"),
    c("c", ["option"                ], "open -a 'Whatsapp'"),
    c("r", ["option"                ], "open -a 'Rider'"),
    c("d", ["option"                ], "open ~/Downloads"),
    c("p", ["option", "left_control"], "open 'raycast://extensions/raycast/clipboard-history/clipboard-history'",),
    c("l", ["option", "left_control"], "open -a 'Lens'"),
    c("d", ["option", "left_control"], "open -a 'Docker Desktop'"),
    c("s", ["option", "left_control"], "open -a 'Slack'"),
    c("o", ["option", "left_control"], "open -a 'Obs'"),
    c("v", ["option", "left_control"], "open -a 'FortiClient'"),
    c("q", ["option", "left_control"], "open -a 'qBittorrent'"),
    c("t", ["option", "left_control"], "~/.config/nvim/scripts/focus_teams_meeting.sh",),
    c("w", ["option", "left_control"], "osascript ~/.config/nvim/scripts/restart_wifi_runner.scpt",),
  ];

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
