import { runCommand } from "../../utils/setup-pc-utils";
import {
  sharedScriptsPath,
  writeRefreshSharedConfigsScript,
  writeSharedFile,
} from "./shared-config";

const publishMpvScriptPath = `${sharedScriptsPath}/publish-mpv.sh`;
const setupMpvScriptPath = `${sharedScriptsPath}/setup-mpv.sh`;

const publishMpvScript = `#!/bin/sh
set -eu

source_directory="$HOME/.config/nvim/dotfiles/mpv"
shared_directory="/Users/Shared/mpv"
managed_entries="input.conf mpv.conf fonts script-opts scripts"
agent_label="codes.ertu.publish-mpv"
agents_directory="$HOME/Library/LaunchAgents"
agent_path="$agents_directory/$agent_label.plist"

publish_config() {
  temporary_directory="$shared_directory.$$"
  trap '/bin/rm -rf "$temporary_directory"' EXIT
  /bin/rm -rf "$temporary_directory"
  /bin/mkdir -p "$temporary_directory"

  for entry in $managed_entries; do
    source="$source_directory/$entry"
    if [ -e "$source" ]; then
      /bin/cp -R "$source" "$temporary_directory/$entry"
    fi
  done

  if [ -d "$shared_directory" ] && /usr/bin/diff -qr "$temporary_directory" "$shared_directory" >/dev/null 2>&1; then
    /bin/rm -rf "$temporary_directory"
    return
  fi

  /bin/chmod -R a+rX "$temporary_directory"
  /bin/rm -rf "$shared_directory"
  /bin/mv "$temporary_directory" "$shared_directory"
}

if [ "\${1:-}" = "--sync" ]; then
  publish_config
  exit 0
fi

publish_config

/bin/mkdir -p "$agents_directory"
temporary_agent="$agent_path.$$"
trap '/bin/rm -f "$temporary_agent"' EXIT
/bin/cat > "$temporary_agent" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>codes.ertu.publish-mpv</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>/Users/Shared/scripts/publish-mpv.sh</string>
    <string>--sync</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>10</integer>
  <key>WatchPaths</key>
  <array>
    <string>$source_directory</string>
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

const setupMpvScript = `#!/bin/sh
set -eu

config_directory="$HOME/.config/mpv"
shared_directory="/Users/Shared/mpv"
managed_entries="input.conf mpv.conf fonts script-opts scripts"
agent_label="codes.ertu.shared-mpv"
agents_directory="$HOME/Library/LaunchAgents"
agent_path="$agents_directory/$agent_label.plist"

sync_config() {
  if [ -L "$config_directory" ]; then
    link_target="$(/usr/bin/readlink "$config_directory")"
    if [ "$link_target" = "$shared_directory" ]; then
      /bin/rm "$config_directory"
    else
      # Keep dotfile-managed configurations intact.
      return
    fi
  fi

  /bin/mkdir -p "$config_directory"

  for entry in $managed_entries; do
    source="$shared_directory/$entry"
    destination="$config_directory/$entry"
    temporary="$config_directory/.$entry.$$"

    if [ ! -e "$source" ]; then
      /bin/rm -rf "$destination"
      continue
    fi

    if [ -e "$destination" ] && /usr/bin/diff -qr "$source" "$destination" >/dev/null 2>&1; then
      continue
    fi

    /bin/rm -rf "$temporary"
    /bin/cp -R "$source" "$temporary"
    /bin/rm -rf "$destination"
    /bin/mv "$temporary" "$destination"
  done
}

if [ "\${1:-}" = "--sync" ]; then
  sync_config
  exit 0
fi

sync_config

/bin/mkdir -p "$agents_directory"
temporary_agent="$agent_path.$$"
trap '/bin/rm -f "$temporary_agent"' EXIT
/bin/cat > "$temporary_agent" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>codes.ertu.shared-mpv</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>/Users/Shared/scripts/setup-mpv.sh</string>
    <string>--sync</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>10</integer>
  <key>WatchPaths</key>
  <array>
    <string>/Users/Shared/mpv</string>
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

export function setupMpvSharing() {
  writeSharedFile(publishMpvScriptPath, publishMpvScript, 0o755);
  writeSharedFile(setupMpvScriptPath, setupMpvScript, 0o755);
  writeRefreshSharedConfigsScript();
  runCommand(`/bin/sh ${publishMpvScriptPath}`);
}

if (import.meta.main) {
  setupMpvSharing();
}
