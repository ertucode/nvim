local status, vscode = pcall(require, "vscode")

if not status then
	return
end

local c = require("vscode.colors").get_colors()
vscode.setup({
	-- Alternatively set style in setup
	style = "dark",

	-- Enable transparent background
	transparent = true,

	-- Enable italic comment
	italic_comments = true,

	-- Disable nvim-tree background color
	disable_nvimtree_bg = true,

	-- Override colors (see ./lua/vscode/colors.lua)
	color_overrides = {
		-- vscLineNumber = "#666666",
	},

	-- Override highlight groups (see ./lua/vscode/theme.lua)
	group_overrides = {
		-- this supports the same val table as vim.api.nvim_set_hl
		-- use colors from this colorscheme by requiring vscode.colors!
		Cursor = { fg = c.vscDarkBlue, bg = c.vscLightGreen, bold = true },
	},
})
vscode.load()

vim.api.nvim_set_hl(0, "Comment", { fg = "#ffff33" })
vim.api.nvim_set_hl(0, "@comment", { link = "Comment" })
