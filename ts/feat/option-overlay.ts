import { cloneOrPullRepo } from "../utils/git";
import { runCommand } from "../utils/setup-pc-utils";

export function setupOptionOverlay() {
  cloneOrPullRepo({
    repo: "git@github.com:ertucode/OptionOverlay.git",
    path: "~/dev/swift/OptionOverlay",
  });

  runCommand("cd ~/dev/swift/OptionOverlay && bun run index.ts");
}
