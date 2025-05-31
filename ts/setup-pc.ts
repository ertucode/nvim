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
