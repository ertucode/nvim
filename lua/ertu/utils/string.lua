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

return M
