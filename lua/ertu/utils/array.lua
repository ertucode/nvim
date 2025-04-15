local M = {}

--- @param tab table
--- @param val any
M.includes = function(tab, val)
	for _, value in ipairs(tab) do
		if value == val then
			return true
		end
	end

	return false
end

--- @param tbl table
--- @param f function
M.map = function(tbl, f)
	local t = {}
	for k, v in pairs(tbl) do
		t[k] = f(v)
	end
	return t
end

--- @param array table
--- @param cb function
M.find = function(array, cb)
	for val, idx in ipairs(array) do
		if cb(val, idx) then
			return val, idx
		end
	end
	return nil
end

--- @param o table
M.dump = function(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. M.dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

--- @param arr table
--- @param fn function
M.filter = function(arr, fn)
	if type(arr) ~= "table" then
		return arr
	end

	local filtered = {}
	for k, v in pairs(arr) do
		if fn(v, k, arr) then
			table.insert(filtered, v)
		end
	end

	return filtered
end

--- Returns a slice of a table.
--- @param tbl table The table to slice.
--- @param from integer The starting index (inclusive).
--- @param to integer? The ending index (inclusive). If nil, defaults to the end of the table.
--- @return table A new table containing the slice.
M.slice = function(tbl, from, to)
	local to_index = to or #tbl
	local result = {}

	for i = from, to_index do
		result[#result + 1] = tbl[i]
	end

	return result
end

return M
