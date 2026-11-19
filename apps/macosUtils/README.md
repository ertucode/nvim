# macOS Utils

A native macOS utility window built with [Rune](https://github.com/anomalyco/rune) and the visual language used by [Hex](https://github.com/anomalyco/hex).

## Build and install

```sh
./install.sh
open "$HOME/Applications/macOS Utils.app"
```

The installer links the command to `~/.local/bin/macos-utils`. Commands focus an existing window or launch a new one:

```sh
macos-utils general
macos-utils processes
macos-utils tmux
macos-utils tmux-dev
macos-utils game-on
macos-utils game-auto
```

`tmux-dev` opens tmux with the `nvim` and `opencode` windows selected. `processes` opens General at the native process picker.
