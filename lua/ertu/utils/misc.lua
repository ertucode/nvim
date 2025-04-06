local M = {}

function M.get_visual_selection_text_table()
	local _, srow, scol = unpack(vim.fn.getpos("v"))
	local _, erow, ecol = unpack(vim.fn.getpos("."))

	-- visual line mode
	if vim.fn.mode() == "V" then
		if srow > erow then
			return vim.api.nvim_buf_get_lines(0, erow - 1, srow, true)
		else
			return vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)
		end
	end

	-- regular visual mode
	if vim.fn.mode() == "v" then
		if srow < erow or (srow == erow and scol <= ecol) then
			return vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
		else
			return vim.api.nvim_buf_get_text(0, erow - 1, ecol - 1, srow - 1, scol, {})
		end
	end

	-- visual block mode
	if vim.fn.mode() == "\22" then
		local lines = {}
		if srow > erow then
			srow, erow = erow, srow
		end
		if scol > ecol then
			scol, ecol = ecol, scol
		end
		for i = srow, erow do
			table.insert(
				lines,
				vim.api.nvim_buf_get_text(0, i - 1, math.min(scol - 1, ecol), i - 1, math.max(scol - 1, ecol), {})[1]
			)
		end
		return lines
	end
end

function M.get_visual_selection_text_string()
	local res = M.get_visual_selection_text_table()

	if res == nil then
		return
	end

	return table.concat(res, "\n")
end

function M.is_string_node(node)
	local type = node:type()
	return type == "string" or type == "string_literal" or type == "string_content" or type == "string_fragment"
end

function M.get_string_under_cursor()
	local ts_utils = require("nvim-treesitter.ts_utils")
	local node = ts_utils.get_node_at_cursor()
	if not node then
		return nil
	end

	-- Check if the node is a string (adjust the query based on the language)
	if M.is_string_node(node) then
		return vim.treesitter.get_node_text(node, 0)
	end
	return nil
end

function M.replace_string_under_cursor(new_string)
	local ts_utils = require("nvim-treesitter.ts_utils")
	local node = ts_utils.get_node_at_cursor()
	if not node then
		return nil
	end

	if not M.is_string_node(node) then
		return
	end

	local start_row, start_col, end_row, end_col = node:range()
	vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, { new_string })
end

return M
