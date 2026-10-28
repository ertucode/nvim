import * as fs from "fs";
import * as os from "os";
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
const sharedScriptsPath = "/Users/Shared/scripts";
const setupKarabinerScriptPath = `${sharedScriptsPath}/setup-karabiner.sh`;
const sharedMpvPath = "/Users/Shared/mpv";
const setupMpvScriptPath = `${sharedScriptsPath}/setup-mpv.sh`;
const refreshSharedConfigsScriptPath = `${sharedScriptsPath}/refresh-configs.sh`;
// Run once from another user's account; future updates can use Cmd+Shift+Ctrl+K:
// /bin/sh /Users/Shared/scripts/refresh-configs.sh

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

const setupMpvScript = `#!/bin/sh
set -eu

config_directory="$HOME/.config/mpv"
shared_directory="/Users/Shared/mpv"

if [ -L "$config_directory" ]; then
  link_target="$(/usr/bin/readlink "$config_directory")"
  if [ "$link_target" = "$shared_directory" ]; then
    /bin/rm "$config_directory"
  else
    # Keep dotfile-managed configurations intact.
    exit 0
  fi
fi

/bin/mkdir -p "$config_directory"

for source in "$shared_directory"/*; do
  [ -e "$source" ] || continue
  name="$(/usr/bin/basename "$source")"
  destination="$config_directory/$name"
  temporary="$config_directory/.$name.$$"

  /bin/rm -rf "$temporary"
  /bin/cp -R "$source" "$temporary"
  /bin/rm -rf "$destination"
  /bin/mv "$temporary" "$destination"
done
`;

const refreshSharedConfigsScript = `#!/bin/sh
set -eu

/bin/sh /Users/Shared/scripts/setup-karabiner.sh
/bin/sh /Users/Shared/scripts/setup-mpv.sh
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

function writeSharedMpvConfig() {
  const sourceDirectory = `${os.homedir()}/.config/nvim/dotfiles/mpv`;
  const temporaryDirectory = `${sharedMpvPath}.${process.pid}-${Date.now()}.tmp`;
  const managedEntries = ["input.conf", "mpv.conf", "script-opts", "scripts"];

  try {
    fs.mkdirSync(temporaryDirectory, { recursive: true, mode: 0o755 });

    for (const entry of managedEntries) {
      const source = `${sourceDirectory}/${entry}`;
      if (fs.existsSync(source)) {
        fs.cpSync(source, `${temporaryDirectory}/${entry}`, {
          recursive: true,
        });
      }
    }

    fs.rmSync(sharedMpvPath, { recursive: true, force: true });
    fs.renameSync(temporaryDirectory, sharedMpvPath);
    fs.chmodSync(sharedMpvPath, 0o755);
  } finally {
    fs.rmSync(temporaryDirectory, { recursive: true, force: true });
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
  writeSharedMpvConfig();
  writeSharedFile(setupMpvScriptPath, setupMpvScript, 0o755);
  writeSharedFile(
    refreshSharedConfigsScriptPath,
    refreshSharedConfigsScript,
    0o755,
  );
  link("~/.config/nvim/dotfiles/karabiner", "~/.config/karabiner", {
    replaceDirectory: true,
  });
}
