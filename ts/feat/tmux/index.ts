import { normalizePath } from "../../utils/file-system";
import { fireAndForget, runCommand } from "../../utils/setup-pc-utils";

export function setupTmux() {
  runCommand("gcc  -framework Carbon CheckModKeys.m -o CheckModKeys", {
    cwd: "~/.config/nvim/ts/feat/tmux/dracula",
  });

  runCommand(
    "git restore . && git apply ~/.config/nvim/ts/feat/tmux/dracula/dracula.patch",
    {
      cwd: "~/.config/tmux/plugins/tmux",
    },
  );

  const path = normalizePath("~/.config/tmux/tmux.conf");
  fireAndForget(["tmux", "source", path]);
}
