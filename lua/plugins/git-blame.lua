return {
	"f-person/git-blame.nvim",
	-- load the plugin at startup, did not work
	-- cmd = "GitBlameToggle",
	event = "VeryLazy",
	config = function()
		require("gitblame").setup({
			enabled = false,
		})
		vim.keymap.set("n", "<leader>bt", ":GitBlameToggle<CR>")
	end,
}
