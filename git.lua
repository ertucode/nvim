---@alias StatusDesc "M"|"A"|"D"|"R"|"C"|" "

---@class FileStatus
---@field file string
---@field staged StatusDesc
---@field not_staged StatusDesc

local function get_file_status(line)
	local chars = line:sub(1, 3)

	return {
		file = line:sub(4),
		staged = chars:sub(1, 1),
		not_staged = chars:sub(2, 2),
	}
end

local function git_status()
	local cmd = "git status --porcelain"
	local lines = vim.fn.systemlist(cmd)
	local staged = {}
	local not_staged = {}
	for _, line in ipairs(lines) do
		local file_status = get_file_status(line)
		if file_status.staged ~= " " then
			table.insert(staged, file_status)
		end
		if file_status.not_staged ~= " " then
			table.insert(not_staged, file_status)
		end
	end
	return {
		staged = staged,
		not_staged = not_staged,
	}
end

local res = git_status()
print(vim.inspect(res))
