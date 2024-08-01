return {
	"jose-elias-alvarez/typescript.nvim",
	config = function()
		require("typescript").setup({})
	end,
	enabled = false,
	keys = {
		{
			"<leader>lru",
			function()
				require("typescript").actions.removeUnused()
			end,
		},
		{
			"<leader>lai",
			function()
				require("typescript").actions.addMissingImports()
			end,
		},
		{
			"<leader>lrf",
			function()
				require("typescript").setup({})
				local ok, res = pcall(vim.cmd, "TypescriptRenameFile")

				if not ok then
					vim.wait(300)
					vim.cmd("TypescriptRenameFile")
				end
			end,
		},
	},
	ft = { "typescript" },
	lazy = false,
}
