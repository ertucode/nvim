return {
	"stevearc/oil.nvim",
	-- tag = "v2.2.0",
	config = function()
		local status, oil = pcall(require, "oil")

		if not status then
			return
		end

		oil.setup({
			skip_confirm_for_simple_edits = true,
			-- lsp_file_methods = {
			-- 	enabled = true,
			-- },
			keymaps = {
				["<C-p>"] = false,
				["<C-s>"] = false,
			},
			watch_for_changes = true,
		})

		vim.keymap.set("n", "-", require("oil").open, { desc = "Open parent directory" })
	end,
}
