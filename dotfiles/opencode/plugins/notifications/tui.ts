import { Plugin } from "@opencode/plugin/tui";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

async function isGhosttyFocused() {
  const { stdout } = await execFileAsync("/usr/bin/osascript", [
    "-e",
    'tell application "System Events" to get name of first application process whose frontmost is true',
  ]);

  return stdout.trim().toLowerCase() === "ghostty";
}

export default Plugin.define({
  id: "notifications.tui",

  setup(ctx) {
    return ctx.data.on("form.created", async (event) => {
      if (await isGhosttyFocused()) return;

      const question = event.data.form.fields
        .map((field) => field.description ?? field.title)
        .filter((text): text is string => Boolean(text))
        .join(" • ");

      await execFileAsync("/opt/homebrew/bin/terminal-notifier", [
        "-title",
        "OpenCode",
        "-subtitle",
        "Yanıtın gerekli",
        "-message",
        question || event.data.form.title,
        "-sound",
        "default",
      ]);
    });
  },
});
