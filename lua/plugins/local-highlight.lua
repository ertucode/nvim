return {
	"tzachar/local-highlight.nvim",
	config = function()
		require("local-highlight").setup({
			cw_hlgroup = "LocalHighlight",
			highlight_single_match = false,
		})
	end,
}
