return {
	"saecki/live-rename.nvim",
	keys = {
		{
			"<leader>lrn",
			function()
				require("live-rename").rename({ insert = true })
			end,
			"LSP rename",
		},
	},
}
