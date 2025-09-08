import z from "zod";
import { checkIfFolderExists } from "../../utils/file-system";
import { cloneOrPullRepo } from "../../utils/git";
import { logInfo } from "../../utils/log";
import { getProcessArgs } from "../../utils/process-args";
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

async function removeOptionOverlay() {
  if (!checkIfFolderExists("~/dev/swift/OptionOverlay")) {
    console.log("OptionOverlay is not installed");
    return;
  }

  runCommand("cd ~/dev/swift/OptionOverlay && bun run undo.ts");
}

if (import.meta.main) {
  const args = getProcessArgs(
    z
      .object({
        remove: z.boolean(),
      })
      .or(z.object({ install: z.boolean() })),
  );

  if ("remove" in args) {
    removeOptionOverlay();
  } else if (args.install) {
    setupOptionOverlay();
  }
}
