import { link } from "../../utils/file-system";
import { runCommand } from "../../utils/setup-pc-utils";
import { setupKarabiner } from "./create-karabiner";
import { setupMacOSDimmer } from "./setup-macos-dimmer";
import { setupMpvSharing } from "./setup-mpv";
import { setupDefaultApps } from "./setup-default-apps";

export { setupMacOSDimmer };

// Run once from another user's account to install automatic updates.
// Cmd+Shift+Ctrl+K remains available as a manual refresh:
// /bin/sh /Users/Shared/scripts/refresh-configs.sh

export async function setupMac() {
  // setupOptionOverlay();
  await setupDefaultApps();
  runCommand("chmod +x ~/.config/nvim/scripts/focus_teams_meeting.sh");
  runCommand("chmod +x ~/.config/nvim/scripts/open_ghostty_command.sh");
  setupMacOSDimmer();

  setupKarabiner();
  setupMpvSharing();
  link("~/.config/nvim/dotfiles/karabiner", "~/.config/karabiner", {
    replaceDirectory: true,
  });
}
