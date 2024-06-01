return {
	"sindrets/diffview.nvim",
	cmd = "DiffviewOpen",
	keys = {
		{
			"<leader>gdo",
			function()
				vim.cmd("DiffviewOpen")
			end,
			desc = "Open diff view",
		},
		{
			"<leader>gdk",
			function()
				vim.cmd("DiffviewClose")
			end,
			desc = "Close diff view",
		},
	},
}
