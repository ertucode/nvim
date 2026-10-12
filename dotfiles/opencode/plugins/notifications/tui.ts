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

async function notify(subtitle: string, message: string) {
  if (await isGhosttyFocused()) return;

  await execFileAsync("/opt/homebrew/bin/terminal-notifier", [
    "-title",
    "OpenCode",
    "-subtitle",
    subtitle,
    "-message",
    message,
    "-sound",
    "default",
  ]);
}

export default Plugin.define({
  id: "notifications.tui",

  setup(ctx) {
    const stopForm = ctx.data.on("form.created", async (event) => {
      const question = event.data.form.fields
        .map((field) => field.description ?? field.title)
        .filter((text): text is string => Boolean(text))
        .join(" • ");

      await notify("Yanıtın gerekli", question || event.data.form.title);
    });

    const stopPermission = ctx.data.on("permission.asked", async (event) => {
      const resources = event.data.resources.join(" • ");
      const message =
        event.data.message ||
        (resources ? `${event.data.action}: ${resources}` : event.data.action);

      await notify("İzin gerekli", message);
    });

    return () => {
      stopForm();
      stopPermission();
    };
  },
});
