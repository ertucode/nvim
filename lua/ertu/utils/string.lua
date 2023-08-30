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

return M
