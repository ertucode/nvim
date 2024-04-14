return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.1",
		-- or                            , branch = '0.1.x',
		dependencies = { { "nvim-lua/plenary.nvim" } },
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
	},
	"nvim-treesitter/nvim-treesitter-context",
	"nvim-treesitter/nvim-treesitter-textobjects",
	"nvim-treesitter/playground",

	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v2.x",
		dependencies = {
			-- LSP Support
			{ "neovim/nvim-lspconfig" }, -- Required
			{ -- Optional
				"williamboman/mason.nvim",
				build = function()
					pcall(vim.cmd, "MasonUpdate")
				end,
			},
			{ "williamboman/mason-lspconfig.nvim" }, -- Optional

			-- Autocompletion
			{ "hrsh7th/nvim-cmp" }, -- Required
			{ "hrsh7th/cmp-nvim-lsp" }, -- Required -- Auto import
			{ "L3MON4D3/LuaSnip" }, -- Required
		},
	},

	-- autopair
	"windwp/nvim-autopairs",
	"windwp/nvim-ts-autotag",

	"tpope/vim-surround",

	-- buffer file explorer
	{
		"stevearc/oil.nvim",
		tag = "v2.2.0",
	},

	-- comment
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	-- vscode theme
	"Mofiqul/vscode.nvim",

	-- Vim status line
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
	},
	"lukas-reineke/indent-blankline.nvim",

	{
		"kana/vim-textobj-entire",
		dependencies = { "kana/vim-textobj-user" },
	},

	"norcalli/nvim-colorizer.lua",

	"ray-x/lsp_signature.nvim",
}
