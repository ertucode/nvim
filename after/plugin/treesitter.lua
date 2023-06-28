require'nvim-treesitter.configs'.setup {
  ensure_installed = { "lua","javascript","typescript" , "vim", "vimdoc", "query" },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}
