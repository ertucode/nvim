local M = {}
M.array = {}

M.find_mapping = function(maps, lhs)
	for _, value in ipairs(maps) do
		if value.lhs == lhs then
			return value
		end
	end
end

M.closing_char = { ")", "}", "]", ">", "'", '"' }

M.array.includes = function(tab, val)
	for _, value in ipairs(tab) do
		if value == val then
			return true
		end
	end

	return false
end

M.get_next_char_that_is_one_of = function(chrs)
	local pos = vim.api.nvim_win_get_cursor(0)
	local row_start = pos[1]

	-- Start from next pos if in normal mode
	local col = vim.api.nvim_get_mode().mode == "n" and pos[2] + 2 or pos[2] + 1

	local lines = vim.api.nvim_buf_get_lines(0, row_start - 1, -1, false)
	local row_offset = 1
	local line = lines[row_offset]

	local char = string.sub(line, col, col)
	while not M.array.includes(chrs, char) do
		col = col + 1
		char = string.sub(line, col, col)
		if char == nil or char == "" then
			row_offset = row_offset + 1
			col = 0
			line = lines[row_offset]
			if line == nil then
				return
			end
		end
	end
	return { row_start + row_offset - 1, col }
end

M.array.find = function(array, cb)
	for val, idx in ipairs(array) do
		if cb(val, idx) then
			return val, idx
		end
	end
	return nil
end

M.qf = {}
M.qf.is_opened = function()
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
