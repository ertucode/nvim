require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"lua",
		"javascript",
		"typescript",
		"vim",
		"vimdoc",
		"query",
		"markdown",
		"json",
		"tsx",
		"dockerfile",
		"html",
		"css",
	},
	sync_install = false,
	auto_install = true,
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
	autopairs = { enable = true },
	indent = { enable = true },
	autotag = { enable = true },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<c-space>",
			node_incremental = "<c-space>",
			-- node_decremental = "<c-bs>", -- doesnt work
		},
	},
})
