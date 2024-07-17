return {
	"nvimdev/lspsaga.nvim",
	config = function()
		require("lspsaga").setup({
			symbol_in_winbar = {
				enable = false,
			},
		})
	end,
	dependencies = {
		"nvim-treesitter/nvim-treesitter", -- optional
		"nvim-tree/nvim-web-devicons", -- optional
	},
	enabled = false,
}
