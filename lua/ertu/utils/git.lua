local M = {}

function M.get_branch()
	return vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")
end

return M
