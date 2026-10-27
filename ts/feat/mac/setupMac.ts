import * as fs from "fs";
import { link, writeFile } from "../../utils/file-system";
import { runCommand } from "../../utils/setup-pc-utils";
import { createKarabiner } from "./create-karabiner";
import {
  sharedClipboardImagePath,
  sharedClipboardImageScript,
  sharedClipboardImageScriptPath,
  sharedClipboardPath,
  sharedClipboardTypePath,
} from "./shared-clipboard";
import { setupDefaultApps } from "./setup-default-apps";

const sharedKarabinerPath = "/Users/Shared/karabiner.json";
const setupKarabinerScriptPath = "/Users/Shared/setup-karabiner.sh";
// Run once from another user's account; future updates can use Cmd+Shift+Ctrl+K:
// /bin/sh /Users/Shared/setup-karabiner.sh

const setupKarabinerScript = `#!/bin/sh
set -eu

config_directory="$HOME/.config/karabiner"
destination="$config_directory/karabiner.json"
temporary_file="$destination.$$"
setup_marker="$config_directory/.shared-setup-initialized"
needs_restart=false
uses_managed_symlink=false

if [ -L "$config_directory" ]; then
  if [ "$(/usr/bin/readlink "$config_directory")" = "/Users/Shared/karabiner" ]; then
    /bin/rm "$config_directory"
    needs_restart=true
  else
    uses_managed_symlink=true
  fi
fi

/bin/mkdir -p "$config_directory"
trap '/bin/rm -f "$temporary_file"' EXIT
/bin/cp /Users/Shared/karabiner.json "$temporary_file"
/bin/chmod 600 "$temporary_file"
/bin/mv "$temporary_file" "$destination"

if [ "$uses_managed_symlink" = false ] && [ ! -e "$setup_marker" ]; then
  /usr/bin/touch "$setup_marker"
  needs_restart=true
fi

if [ "$needs_restart" = true ]; then
  /bin/launchctl kickstart -k "gui/$(/usr/bin/id -u)/org.pqrs.service.agent.karabiner_console_user_server"
fi
`;

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

function writeSharedFile(destination: string, content: string, mode: number) {
  const temporaryFile = `${destination}.${process.pid}-${Date.now()}.tmp`;

  try {
    fs.writeFileSync(temporaryFile, content, { encoding: "utf8", mode });
    fs.chmodSync(temporaryFile, mode);
    fs.renameSync(temporaryFile, destination);
  } finally {
    fs.rmSync(temporaryFile, { force: true });
  }
}

export async function setupMac() {
  // setupOptionOverlay();
  await setupDefaultApps();
  runCommand("chmod +x ~/.config/nvim/scripts/focus_teams_meeting.sh");
  runCommand("chmod +x ~/.config/nvim/scripts/open_ghostty_command.sh");

  const karabiner = createKarabiner();
  const karabinerJson = JSON.stringify(karabiner);

  writeFile("~/.config/nvim/dotfiles/karabiner/karabiner.json", karabinerJson);
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
  link("~/.config/nvim/dotfiles/karabiner", "~/.config/karabiner", {
    replaceDirectory: true,
  });
}
