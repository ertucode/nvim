local M = {}

local function diagnostic_move_pos(diag)
	local win_id = vim.api.nvim_get_current_win()
	local pos = { diag.lnum, diag.col }

	vim.api.nvim_win_call(win_id, function()
		vim.api.nvim_win_set_cursor(win_id, { pos[1] + 1, pos[2] })
		-- Open folds under the cursor
		vim.cmd("normal! zv")
	end)
end

M.remove_unused = function()
	local params = {
		command = "_typescript.organizeImports",
		arguments = { vim.api.nvim_buf_get_name(0) },
		title = "",
	}
	vim.lsp.buf.execute_command(params)
end

local find_missing_diag = function()
	local diags = vim.diagnostic.get(0)
	if #diags == 0 then
		return
	end

	for _, diag in ipairs(diags) do
		if diag.message ~= nil and diag.message:find("^Cannot find name") then
			return diag
		end
	end
end
M.import_missing = function()
	local missing = find_missing_diag()
	if missing == nil then
		return
	end

	local view = vim.fn.winsaveview()

	diagnostic_move_pos(missing)

	vim.lsp.buf.code_action({
		filter = function(action)
			return action.title == "Add all missing imports"
		end,
		apply = true,
	})

	vim.fn.winrestview(view)

	-- vim.cmd(":%substitute/@radix-ui\\/react-/@\\/ui\\/components\\//")
end

return M
