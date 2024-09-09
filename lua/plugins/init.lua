return {
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
	},
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
