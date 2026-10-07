import { configureGit } from "./feat/git";
import { setupMac } from "./feat/mac/setupMac";
import { setupTmux } from "./feat/tmux";
import { link } from "./utils/file-system";
import { getPlatformType } from "./utils/platform";
import { ensureLinesInFile } from "./utils/setup-pc-utils";

link("~/.config/nvim/dotfiles/starsip.toml", "~/.config/starship.toml");
link("~/.config/nvim/dotfiles/p10k.zsh", "~/.p10k.zsh");
link(
  "~/.config/nvim/dotfiles/alacritty.toml",
  "~/.config/alacritty/alacritty.toml",
);
link("~/.config/nvim/dotfiles/ideavimrc", "~/.ideavimrc");
link("~/.config/nvim/dotfiles/neovide", "~/.config/neovide", {
  replaceDirectory: true,
});
link("~/.config/nvim/dotfiles/opencode", "~/.config/opencode", {
  replaceDirectory: true,
});
link("~/.config/nvim/dotfiles/mpv", "~/.config/mpv", {
  replaceDirectory: true,
});
link("~/.config/nvim/dotfiles/ghostty", "~/.config/ghostty", {
  replaceDirectory: true,
});

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
