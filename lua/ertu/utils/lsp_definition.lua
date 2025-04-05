local M = {}

local filter = require("ertu.utils.array").filter

local function is_typescript_client(client)
	return client.name == "tsserver" or client.name == "vtsls" or client.name == "ts_ls"
end

local function result_item_uri(value)
	return value.uri or value.targetUri
end

local function filter_react_dts(value)
	local uri = result_item_uri(value)
	return string.match(uri, "react/index.d.ts") == nil
end

local function results_are_same_line(values)
	local uri = result_item_uri(values[1])
	local line = values[1].targetRange.start.line

	for _, value in pairs(values) do
		if result_item_uri(value) ~= uri then
			return false
		end
		if value.targetRange.start.line ~= line then
			return false
		end
	end
	return true
end

local function origin_and_target_same(result_item)
	local target = result_item.targetSelectionRange -- targetRange?
	local origin = result_item.originSelectionRange
	local current_file_uri = vim.uri_from_bufnr(0)
	if current_file_uri ~= result_item_uri(result_item) then
		return false
	end
	return target["end"]["character"] == origin["end"].character
		and target["end"]["line"] == origin["end"].line
		and target["start"]["character"] == origin["start"].character
		and target["start"]["line"] == origin["start"].line
end

local function filter_non_moving(results)
	return filter(results, function(result)
		return not origin_and_target_same(result)
	end)
end

local function on_response_or_find_references(error, result_item, client, on_response)
	if origin_and_target_same(result_item) then
		require("telescope.builtin").lsp_references()
		return
	end

	on_response(error, result_item, client)
end

--- @param client vim.lsp.Client
local function custom_on_response(error, result, client, on_response)
	if not vim.islist(result) then
		return on_response(error, result, client)
	end

	result = filter_non_moving(result)

	if #result == 1 then
		return on_response_or_find_references(error, result[1], client, on_response)
	end

	if is_typescript_client(client) then
		local filtered = filter(result, filter_react_dts)
		if #filtered == 1 then
			return on_response_or_find_references(error, filtered[1], client, on_response)
		end
	end

	if results_are_same_line(result) then
		return on_response_or_find_references(error, result[1], client, on_response)
	end

	require("telescope.builtin").lsp_definitions()
end

---@param method string
---@param opts? vim.lsp.LocationOpts
local function get_locations(method, opts)
	opts = opts or {}
	local bufnr = vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({ method = method, bufnr = bufnr })
	if not next(clients) then
		vim.notify(vim.lsp._unsupported_method(method), vim.log.levels.WARN)
		return
	end
	local win = vim.api.nvim_get_current_win()
	local from = vim.fn.getpos(".")
	from[1] = bufnr
	local tagname = vim.fn.expand("<cword>")
	local remaining = #clients

	---@type vim.quickfix.entry[]
	local all_items = {}

	---@param result nil|lsp.Location|lsp.Location[]
	---@param client vim.lsp.Client
	local function on_response(_, result, client)
		local locations = {}
		if result then
			locations = vim.islist(result) and result or { result }
		end
		local items = vim.lsp.util.locations_to_items(locations, client.offset_encoding)
		vim.list_extend(all_items, items)
		remaining = remaining - 1
		if remaining == 0 then
			if vim.tbl_isempty(all_items) then
				vim.notify("No locations found", vim.log.levels.INFO)
				return
			end

			local title = "LSP locations"
			if opts.on_list then
				assert(vim.is_callable(opts.on_list), "on_list is not a function")
				opts.on_list({
					title = title,
					items = all_items,
					context = { bufnr = bufnr, method = method },
				})
				return
			end

			if #all_items == 1 then
				local item = all_items[1]
				local b = item.bufnr or vim.fn.bufadd(item.filename)

				-- Save position in jumplist
				vim.cmd("normal! m'")
				-- Push a new item into tagstack
				local tagstack = { { tagname = tagname, from = from } }
				vim.fn.settagstack(vim.fn.win_getid(win), { items = tagstack }, "t")

				vim.bo[b].buflisted = true
				local w = opts.reuse_win and vim.fn.win_findbuf(b)[1] or win
				vim.api.nvim_win_set_buf(w, b)
				vim.api.nvim_win_set_cursor(w, { item.lnum, item.col - 1 })
				vim._with({ win = w }, function()
					-- Open folds under the cursor
					vim.cmd("normal! zv")
				end)
				return
			end
			if opts.loclist then
				vim.fn.setloclist(0, {}, " ", { title = title, items = all_items })
				vim.cmd.lopen()
			else
				vim.fn.setqflist({}, " ", { title = title, items = all_items })
				vim.cmd("botright copen")
			end
		end
	end
	for _, client in ipairs(clients) do
		local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
		client:request(method, params, function(_, result)
			custom_on_response(_, result, client, on_response)
		end)
	end
end

--- @param opts? vim.lsp.LocationOpts
function M.definition(opts)
	get_locations("textDocument/definition", opts)
end

return M
