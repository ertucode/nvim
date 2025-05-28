import { normalizePath } from "../../utils/file-system";
import { cloneOrPullRepo } from "../../utils/git";
import { fireAndForget, link, runCommand } from "../../utils/setup-pc-utils";

export async function setupTmux() {
  const tmuxDir = normalizePath("~/.config/tmux");
  runCommand(`mkdir -p ${tmuxDir}`);

  await cloneOrPullRepo({
    repo: "https://github.com/tmux-plugins/tpm",
    path: normalizePath("~/.tmux/plugins/tpm"),
  });

  const installPluginsPath = normalizePath(
    "~/.tmux/plugins/tpm/bin/install_plugins",
  );
  runCommand(installPluginsPath);

  runCommand("gcc  -framework Carbon CheckModKeys.m -o CheckModKeys", {
    cwd: "~/.config/nvim/ts/feat/tmux/dracula",
  });

  runCommand(
    "git restore . && git apply ~/.config/nvim/ts/feat/tmux/dracula/dracula.patch",
    {
      cwd: "~/.config/tmux/plugins/tmux",
    },
  );

  link("~/.config/nvim/ts/feat/tmux/tmux.conf", "~/.config/tmux/tmux.conf");
  link(
    "~/.config/nvim/ts/feat/tmux/tmux-sessionizer",
    "~/.config/tmux/tmux-sessionizer",
  );

  const path = normalizePath("~/.config/tmux/tmux.conf");
  fireAndForget(["tmux", "source", path]);
}
