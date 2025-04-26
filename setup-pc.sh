#!/bin/bash

ln -sf ~/.config/nvim/starsip.toml ~/.config/starship.toml

mkdir -p ~/.config/alacritty

ln -sf ~/.config/nvim/alacritty.toml ~/.config/alacritty/alacritty.toml
ln -sf ~/.config/nvim/ideavimrc ~/.ideavimrc

ensure_line_in_file() {
  local line="$1"
  local file="$2"

  # Create the file if it doesn't exist
  [ -f "$file" ] || touch "$file"

  # Check if the line already exists
  grep -Fxq "$line" "$file" || echo "$line" >> "$file"
}

ensure_line_in_file "source ~/.config/nvim/helpers.zshrc" "$HOME/.zshrc"
ensure_line_in_file "export MANPAGER='nvim +Man!'" "$HOME/.zshrc"
ensure_line_in_file "defaults write -g InitialKeyRepeat -int 10" "$HOME/.zshrc"
ensure_line_in_file "defaults write -g KeyRepeat -int 2" "$HOME/.zshrc"
