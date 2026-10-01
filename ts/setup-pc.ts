import { configureGit } from "./feat/git";
import { setupMac } from "./feat/mac/setupMac";
import { setupTmux } from "./feat/tmux";
import { link } from "./utils/file-system";
import { getPlatformType } from "./utils/platform";
import { ensureLinesInFile } from "./utils/setup-pc-utils";

link("~/.config/nvim/dotfiles/starsip.toml", "~/.config/starship.toml");
link(
  "~/.config/nvim/dotfiles/alacritty.toml",
  "~/.config/alacritty/alacritty.toml",
);
link("~/.config/nvim/dotfiles/ideavimrc", "~/.ideavimrc");
link("~/.config/nvim/dotfiles/neovide", "~/.config/neovide");
link("~/.config/nvim/dotfiles/opencode", "~/.config/opencode");
link("~/.config/nvim/dotfiles/mpv", "~/.config/mpv");
link("~/.config/nvim/dotfiles/ghostty", "~/.config/ghostty");

ensureLinesInFile({
  lines: ["source ~/.config/nvim/dotfiles/helpers.zshrc"],
  filePath: "~/.zshrc",
});

configureGit();

setupTmux();

const platform = getPlatformType();

if (platform === "mac") {
  await setupMac();
}
