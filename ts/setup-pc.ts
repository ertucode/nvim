import { link, ensureLinesInFile } from "./utils/setup-pc-utils";

link("~/.config/nvim/dotfiles/starsip.toml", "~/.config/starship.toml");
link(
  "~/.config/nvim/dotfiles/alacritty.toml",
  "~/.config/alacritty/alacritty.toml",
);
link("~/.config/nvim/dotfiles/ideavimrc", "~/.ideavimrc");
link("~/.config/nvim/dotfiles/karabiner", "~/.config/karabiner");

ensureLinesInFile({
  lines: ["source ~/.config/nvim/dotfiles/helpers.zshrc"],
  filePath: "~/.zshrc",
});
