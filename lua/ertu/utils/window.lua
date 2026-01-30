local M = {}

M.swap_vertical = function()
	vim.cmd("wincmd j")
	vim.cmd("wincmd k")
	vim.cmd("wincmd x")
end

return M
