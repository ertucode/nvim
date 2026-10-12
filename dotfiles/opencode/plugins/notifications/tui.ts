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

let tmuxPath: string | null | undefined;

async function findTmux(): Promise<string | null> {
  if (tmuxPath !== undefined) return tmuxPath;

  for (const candidate of [
    "/opt/homebrew/bin/tmux",
    "/usr/local/bin/tmux",
    "/usr/bin/tmux",
  ]) {
    try {
      await execFileAsync(candidate, ["-V"]);
      tmuxPath = candidate;
      return tmuxPath;
    } catch {}
  }

  try {
    const { stdout } = await execFileAsync("/bin/zsh", [
      "-lc",
      "command -v tmux",
    ]);
    tmuxPath = stdout.trim().split("\n")[0] || null;
  } catch {
    tmuxPath = null;
  }

  return tmuxPath;
}

async function tmux(args: string[]): Promise<string> {
  const path = await findTmux();
  if (!path) throw new Error("tmux not found");

  const { stdout } = await execFileAsync(path, args);
  return stdout;
}

type Pane = { pid: number; id: string; session: string; window: string };

async function findOpencodePane(): Promise<Pane | null> {
  const output = await tmux([
    "list-panes",
    "-a",
    "-F",
    "#{pane_pid} #{pane_id} #{session_name}:#{window_index}.#{pane_index}",
  ]);

  const panes: Pane[] = [];
  for (const line of output.split("\n")) {
    const match = line.trim().match(/^(\d+)\s+(\S+)\s+(\S+):(\d+)\.(\d+)$/);
    if (match) {
      panes.push({
        pid: Number(match[1]),
        id: match[2],
        session: match[3],
        window: match[4],
      });
    }
  }
  if (panes.length === 0) return null;

  // Walk up from this process to the shell whose pane OpenCode runs in.
  const ps = await execFileAsync("/bin/ps", ["-axo", "pid=,ppid="]);
  const parentOf = new Map<number, number>();
  for (const line of ps.stdout.split("\n")) {
    const match = line.trim().match(/^(\d+)\s+(\d+)$/);
    if (match) parentOf.set(Number(match[1]), Number(match[2]));
  }

  let pid: number | undefined = process.pid;
  for (let depth = 0; pid !== undefined && depth < 64; depth++) {
    const pane = panes.find((p) => p.pid === pid);
    if (pane) return pane;
    pid = parentOf.get(pid);
  }

  return null;
}

async function isTmuxPaneVisible(): Promise<boolean> {
  try {
    const pane = await findOpencodePane();
    if (!pane) return true; // OpenCode is not running inside a tmux pane

    // Is a client attached to our session at all?
    const clients = await tmux(["list-clients", "-F", "#{client_session}"]);
    const attached = clients
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean)
      .includes(pane.session);
    if (!attached) return false;

    // Is our window the current window of our session?
    const windows = await tmux([
      "list-windows",
      "-t",
      pane.session,
      "-F",
      "#{window_index} #{window_active}",
    ]);
    const activeWindow = windows
      .split("\n")
      .map((line) => line.trim().split(/\s+/))
      .find((fields) => fields[1] === "1");
    if (!activeWindow || activeWindow[0] !== pane.window) return false;

    // Is our pane the active pane of that window?
    const panes = await tmux([
      "list-panes",
      "-t",
      `${pane.session}:${pane.window}`,
      "-F",
      "#{pane_id} #{pane_active}",
    ]);
    return panes
      .split("\n")
      .map((line) => line.trim().split(/\s+/))
      .some(([id, active]) => id === pane.id && active === "1");
  } catch {
    return true; // tmux unavailable — keep the Ghostty-only behavior
  }
}

async function notify(subtitle: string, message: string) {
  // Only stay silent when the user is looking right at OpenCode: Ghostty is
  // the frontmost app and our tmux pane is the one on screen.
  if (await isGhosttyFocused() && (await isTmuxPaneVisible())) return;

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
