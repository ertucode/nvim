-- vim internalları kopyalanarak yapıldı.
local M = {}

local function filter(arr, fn)
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

local function gdUri(value)
	return value.uri or value.targetUri
end

local function filterReactDTS(value)
	local uri = gdUri(value)
	return string.match(uri, "react/index.d.ts") == nil
end

local function everyOneIsSameLine(values)
	local uri = gdUri(values[1])
	for _, value in pairs(values) do
		if gdUri(value) ~= uri then
			return nil
		end
	end
	return values[1]
end

--- @param client vim.lsp.Client
local function custom_on_response(error, result, client, on_response)
	if not vim.islist(result) or #result == 1 then
		local first = result[1]
		local target = first.targetSelectionRange -- targetRange?
		local origin = first.originSelectionRange
		if
			target["end"]["character"] == origin["end"].character
			and target["end"]["line"] == origin["end"].line
			and target["start"]["character"] == origin["start"].character
			and target["start"]["line"] == origin["start"].line
		then
			require("telescope.builtin").lsp_references()
			return
		end
	end

	if not (client.name == "tsserver" or client.name == "vtsls" or client.name == "ts_ls") then
		on_response(error, result, client)
		return
	end

	if vim.islist(result) and #result > 1 then
		local filtered = filter(result, filterReactDTS)
		if #filtered <= 1 then
			on_response(error, result, client)
			return
		end

		local sameLine = everyOneIsSameLine(result)
		if sameLine ~= nil then
			on_response(error, result, client)
			return
		end

		require("telescope.builtin").lsp_definitions()
		return
	end

	return on_response(error, result, client)
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
