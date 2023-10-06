local status, ibl = pcall(require, "ibl")

if not status then
	return
end

local highlight = {
	"IBL_SOFT",
}

local hooks = require("ibl.hooks")
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
	vim.api.nvim_set_hl(0, "IBL_SOFT", { fg = "#444444" })
end)

ibl.setup({
	indent = {
		highlight = highlight,
		char = { "▏" },
	},
	scope = {
		enabled = false,
	},
})
