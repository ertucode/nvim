import { cloneOrPullRepo } from "../../utils/git";
import { logInfo } from "../../utils/log";
import { runCommand } from "../../utils/setup-pc-utils";

export async function setupOptionOverlay() {
  const res = await cloneOrPullRepo({
    repo: "git@github.com:ertucode/OptionOverlay.git",
    path: "~/dev/swift/OptionOverlay",
  });

  if (res.alreadyUpToDate) {
    logInfo("OptionOverlay is already up to date");
    return;
  }

  runCommand("cd ~/dev/swift/OptionOverlay && bun run index.ts");
}
