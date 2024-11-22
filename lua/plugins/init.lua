return {
	{
		"nvim-treesitter/playground",
		cmd = "TSPlaygroundToggle",
	},

	{
		"kana/vim-textobj-entire",
		event = "BufRead",
		dependencies = { "kana/vim-textobj-user" },
	},
}
