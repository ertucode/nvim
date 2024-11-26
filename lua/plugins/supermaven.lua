return {
	"supermaven-inc/supermaven-nvim",
	config = function()
		require("supermaven-nvim").setup({
			-- keymaps = {
			-- accept_suggestion = "<M-l>",
			-- clear_suggestion = "<C-]>",
			-- accept_word = "<C-j>",
			-- },
			-- ignore_filetypes = { cpp = true }, -- or { "cpp", }
			-- color = {
			-- 	suggestion_color = "#bbb",
			-- 	cterm = 244,
			-- },
			-- log_level = "info", -- set to "off" to disable logging completely
			disable_inline_completion = false, -- disables inline completion for use with cmp
			disable_keymaps = true, -- disables built in keymaps for more manual control
			condition = function()
				return false
			end, -- condition to check for stopping supermaven, `true` means to stop supermaven when the condition is true.
		})

		vim.keymap.set("i", "<M-l>", function()
			local suggestion = require("supermaven-nvim.completion_preview")
			if suggestion.has_suggestion() then
				suggestion.on_accept_suggestion()
			end
		end)
	end,
}
