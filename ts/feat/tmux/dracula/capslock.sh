#!/usr/bin/env bash

output=$("$HOME/.config/nvim/ts/feat/tmux/dracula/CheckModKeys" capslock)

if [ "$output" = "1" ]; then
  echo "■"
else
  echo "□"
fi
sleep 1
