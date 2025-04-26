local M = {}

local REGISTER = "z"
local state_home = os.getenv("XDG_STATE_HOME") or (vim.fn.stdpath("state"))
local FILE_PATH = state_home .. "/lastcopy"

function M.save_last_yank()
	local event = vim.v.event
	if event.regname ~= "" then
		return
	end
	local yank_data = {
		contents = event.regcontents,
		type = event.regtype,
	}

	local json = vim.fn.json_encode(yank_data)

	vim.fn.mkdir(vim.fn.fnamemodify(FILE_PATH, ":h"), "p")
	vim.fn.writefile({ json }, FILE_PATH)
end

function M.custom_paste(paste_letter)
	if vim.fn.filereadable(FILE_PATH) == 0 then
		print("No last yank available.")
		return ""
	end

	local lines = vim.fn.readfile(FILE_PATH)
	if not lines or #lines == 0 then
		print("Empty lastcopy file.")
		return ""
	end

	local ok, data = pcall(vim.fn.json_decode, table.concat(lines, ""))
	if not ok or not data then
		print("Failed to decode lastcopy file.")
		return ""
	end

	local regtype = data.type or "v"
	local contents = data.contents or {}

	vim.fn.setreg(REGISTER, contents, regtype)

	return '"' .. REGISTER .. paste_letter
end

function M.create_handler(letter)
	return function()
		if vim.v.register == '"' then
			return M.custom_paste(letter)
		else
			return letter
		end
	end
end

function M.setup()
	vim.keymap.set("n", "p", M.create_handler("p"), { expr = true })
	vim.keymap.set("n", "P", M.create_handler("P"), { expr = true })

	vim.api.nvim_create_autocmd("TextYankPost", {
		group = vim.api.nvim_create_augroup("YankPaste", { clear = true }),
		callback = M.save_last_yank,
	})
end

return M
