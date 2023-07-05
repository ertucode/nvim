require("oil").setup({
    keymaps = {
        ["<C-p>"] = false,
    },
})

vim.keymap.set("n", "-", require("oil").open, { desc = "Open parent directory" })
