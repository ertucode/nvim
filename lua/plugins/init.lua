return {
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
	},
	"nvim-treesitter/playground",

	-- {
	-- 	"VonHeikemen/lsp-zero.nvim",
	-- 	branch = "v2.x",
	-- 	dependencies = {
	-- 		-- LSP Support
	-- 		{ "neovim/nvim-lspconfig" }, -- Required
	-- 		{ -- Optional
	-- 			"williamboman/mason.nvim",
	-- 			build = function()
	-- 				pcall(vim.cmd, "MasonUpdate")
	-- 			end,
	-- 		},
	-- 		{ "williamboman/mason-lspconfig.nvim" }, -- Optional
	--
	-- 		-- Autocompletion
	-- 		{ "hrsh7th/nvim-cmp" }, -- Required
	-- 		{ "hrsh7th/cmp-nvim-lsp" }, -- Required -- Auto import
	-- 		{ "L3MON4D3/LuaSnip" }, -- Required
	-- 	},
	-- },

	"tpope/vim-surround",

	-- comment
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	{
		"kana/vim-textobj-entire",
		dependencies = { "kana/vim-textobj-user" },
	},
}
