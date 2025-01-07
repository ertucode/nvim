local M = {}

M.is_opened = function()
	local bufs = vim.fn.getbufinfo()
	local found = false
	for _, value in pairs(bufs) do
		if value.variables and value.variables.current_syntax == "qf" and value.hidden == 0 then
			found = true
		end
	end
	return found
end

return M
