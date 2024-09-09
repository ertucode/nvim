return {
	"numToStr/Comment.nvim",
	event = "VeryLazy",
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
		opts = {
			enable_autocmd = false,
		},
	},
	config = function()
		local status, comment = pcall(require, "Comment")

		if not status then
			return
		end

		comment.setup({
			opleader = {
				line = "gc",
				block = "gb",
			},
			pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
			mappings = {
				-- gcc line comment
				-- gcb block comment
				-- gc[count][motion] line comment region contained in motion
				-- gb[count][motion] block comment region contained in motion
				basic = true,
				-- gco, gcO, gcA
				extra = true,
			},
			toggler = {
				line = "gcc",
				block = "gbc",
			},
		})
	end,
}
