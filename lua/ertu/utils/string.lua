local M = {}

M.firstToUpper = function(str)
	return (str:gsub("^%l", string.upper))
end

M.camelToCapital = function(text)
	local splits = vim.split(text, "-", { plain = true, triempty = true })
	local ret = ""

	for _, value in ipairs(splits) do
		ret = ret .. M.firstToUpper(value)
	end
	return ret
end

function M.truncated(text, max_len, with_dot)
	local truncated_context = string.sub(text, 1, max_len)
	if truncated_context ~= text and with_dot then
		truncated_context = truncated_context .. ".."
	end
	return truncated_context
end

M.closing_char = { ")", "}", "]", ">", "'", '"' }

M.get_next_char_that_is_one_of = function(chrs)
	local pos = vim.api.nvim_win_get_cursor(0)
	local row_start = pos[1]

	-- Start from next pos if in normal mode
	local col = vim.api.nvim_get_mode().mode == "n" and pos[2] + 2 or pos[2] + 1

	local lines = vim.api.nvim_buf_get_lines(0, row_start - 1, -1, false)
	local row_offset = 1
	local line = lines[row_offset]

	local char = string.sub(line, col, col)
	local includes = require("ertu.utils.array").includes
	while not includes(chrs, char) do
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

---@param text string
---@param search string
---@return boolean
M.includes = function(text, search)
	return text:find(search, 1, true) ~= nil
end

return M
