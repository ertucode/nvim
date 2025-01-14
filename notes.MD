### incremental search
/\ccaseinsensitive
:set ignorecase - :set ic (:set smartcase (Switch to noignorecase when uppercase letter is used))
:set noignorecase - :set noic

### simple picker
https://www.youtube.com/watch?v=BMTXuY640dA

### lazy.nvim
- init: Runs before plugin is required
- config: If not provided the default is running require("pluginname").setup(opts). Otherwise should setup plugin manually
- opts: Useful only when config is not provided

### autocmd
- https://www.youtube.com/watch?v=HR1dKKrOmDs&t=29s
```lua
local data = {
  buf = vim.fn.expand("<abuf>") -- afile, amatch
}
```

### telescope
- fzf icin fzf ve cmake olmali sistemde
- string grep icin ripgrep

### configs
- ln -s ~/.config/nvim/starsip.toml ~/.config/starship.toml
- mkdir ~/.config/alacritty
- ln -s ~/.config/nvim/alacritty.toml ~/.config/alacritty/alacritty.toml
