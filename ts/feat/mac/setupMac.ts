import { link, writeFile } from "../../utils/file-system";
import { runCommand } from "../../utils/setup-pc-utils";
import { createKarabiner } from "./create-karabiner";
import { setupDefaultApps } from "./setup-default-apps";

export async function setupMac() {
  // setupOptionOverlay();
  await setupDefaultApps();
  runCommand("chmod +x ~/.config/nvim/scripts/focus_teams_meeting.sh");

  const karabiner = createKarabiner();

  writeFile("~/.config/karabiner/karabiner.json", JSON.stringify(karabiner));
  link("~/.config/nvim/dotfiles/karabiner", "~/.config/karabiner");
}
