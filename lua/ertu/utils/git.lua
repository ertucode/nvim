local M = {}

function M.get_branch()
	return vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")
end

---@alias GitFileState "M"|"A"|"D"|"R"|"C"|"U" M=Modified, A=Added, D=Deleted, R=Renamed, C=Copied, U=Updated but unmerged

---@class ChangedFile
---@field name string
---@field state GitFileState

---Get list of changed files from git status --porcelain
---@return ChangedFile[]
function M.get_changed_files()
	local result = {}
	local output = vim.fn.system("git status --porcelain")

	for line in output:gmatch("[^\r\n]+") do
		if #line >= 3 then
			local state = line:sub(1, 2)
			local name = line:sub(4)

			if state ~= "??" and state ~= "!!" then
				local file_state = state:gsub(" ", ""):gsub("%?", "")
				if #file_state > 0 then
					table.insert(result, { name = name, state = file_state })
				end
			end
		end
	end

	return result
end

return M
