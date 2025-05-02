import { link, ensureLinesInFile } from "./ts/setup-pc-utils";

link("~/.config/nvim/starsip.toml", "~/.config/starship.toml");
link("~/.config/nvim/alacritty.toml", "~/.config/alacritty/alacritty.toml");
link("~/.config/nvim/ideavimrc", "~/.ideavimrc");
link("~/.config/nvim/karabiner", "~/.config/karabiner");

ensureLinesInFile({
  lines: ["source ~/.config/nvim/helpers.zshrc"],
  filePath: "~/.zshrc",
});
