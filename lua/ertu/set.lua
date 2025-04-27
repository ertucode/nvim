vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 30

vim.opt.colorcolumn = "300"

-- fold
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldcolumn = "0"
vim.opt.foldtext = ""
vim.opt.foldlevel = 99
-- vim.opt.foldlevelstart = 1
-- vim.opt.foldnestmax = 4
-- zR zM za zk zj

-- mine
vim.opt.cursorline = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.diagnostic.config({
	-- virtual_lines = {
	-- 	current_line = true,
	-- },
	virtual_text = true,
	severity_sort = true,
	update_in_insert = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = "󰠠 ",
		},
		-- linehl = {
		-- 	[vim.diagnostic.severity.ERROR] = "Error",
		-- 	[vim.diagnostic.severity.WARN] = "Warn",
		-- 	[vim.diagnostic.severity.INFO] = "Info",
		-- 	[vim.diagnostic.severity.HINT] = "Hint",
		-- },
	},
})

local function set_diff_highlights()
	vim.api.nvim_set_hl(0, "DiffAdd", { fg = "none", bg = "#283B4D", bold = true })
	vim.api.nvim_set_hl(0, "DiffDelete", { fg = "none", bg = "#6B2F4B", bold = true })
	vim.api.nvim_set_hl(0, "DiffChange", { fg = "none", bg = "#2B3C66", bold = true })
	vim.api.nvim_set_hl(0, "DiffText", { fg = "none", bg = "#004400", bold = true })
end

set_diff_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("DiffColors", { clear = true }),
	callback = set_diff_highlights,
})

require("ertu.utils.inter-session-yanking").setup()
