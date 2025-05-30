import { runCommand } from "../../utils/setup-pc-utils";
import { setupOptionOverlay } from "./option-overlay";
import { setupDefaultApps } from "./setup-default-apps";

export async function setupMac() {
  // setupOptionOverlay();
  await setupDefaultApps();
  runCommand("chmod +x ./ts/feat/mac/focus_teams_meeting.sh");
}
