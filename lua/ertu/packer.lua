vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
	-- Packer can manage itself
	use("wbthomason/packer.nvim")

	use({
		"nvim-telescope/telescope.nvim",
		tag = "0.1.1",
		-- or                            , branch = '0.1.x',
		requires = { { "nvim-lua/plenary.nvim" } },
	})

	use({
		"nvim-telescope/telescope-fzf-native.nvim",
		run = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
	})

	use("nvim-treesitter/nvim-treesitter", { run = ":TSUpdate" })
	use("nvim-treesitter/nvim-treesitter-context")
	use("nvim-treesitter/nvim-treesitter-textobjects")
	use("nvim-treesitter/playground")

	use("theprimeagen/harpoon")

	use({
		"VonHeikemen/lsp-zero.nvim",
		branch = "v2.x",
		requires = {
			-- LSP Support
			{ "neovim/nvim-lspconfig" }, -- Required
			{ -- Optional
				"williamboman/mason.nvim",
				run = function()
					pcall(vim.cmd, "MasonUpdate")
				end,
			},
			{ "williamboman/mason-lspconfig.nvim" }, -- Optional

			-- Autocompletion
			{ "hrsh7th/nvim-cmp" }, -- Required
			{ "hrsh7th/cmp-nvim-lsp" }, -- Required -- Auto import
			{ "L3MON4D3/LuaSnip" }, -- Required
		},
	})

	-- completion
	use("hrsh7th/cmp-buffer") -- Get completion from current file even if its not a symbol
	use("hrsh7th/cmp-path")
	use("hrsh7th/cmp-nvim-lua") -- Knows nvim api
	use("saadparwaiz1/cmp_luasnip") -- Snip and comp adapter ?
	use("onsails/lspkind.nvim")

	-- autopair
	use("windwp/nvim-autopairs")
	use("windwp/nvim-ts-autotag")

	use("tpope/vim-surround")

	-- buffer file explorer
	use({
		"stevearc/oil.nvim",
		tag = "v2.2.0",
	})

	-- prettier
	use("jose-elias-alvarez/null-ls.nvim")
	use("jayp0521/mason-null-ls.nvim")

	-- comment
	use({
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	})

	-- vscode theme
	use("Mofiqul/vscode.nvim")

	-- Vim status line
	use({
		"nvim-lualine/lualine.nvim",
		requires = { "nvim-tree/nvim-web-devicons", opt = true },
	})
	use("lukas-reineke/indent-blankline.nvim")

	use({
		"kana/vim-textobj-entire",
		requires = { "kana/vim-textobj-user" },
	})

	use("norcalli/nvim-colorizer.lua")

	use("nvim-tree/nvim-web-devicons")

	use("ray-x/lsp_signature.nvim")
end)
