local M = {}

local filter = require("ertu.utils.array").filter
local internal_definition = require("ertu.utils.lsp_internal").definition

local function lsp_references(opts)
	return require("telescope.builtin").lsp_references(opts)
end

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
		return lsp_references()
	end

	on_response(error, result_item, client)
end

--- @param client vim.lsp.Client
local function custom_on_response(error, result, client, on_response)
	if not vim.islist(result) then
		return on_response(error, result, client)
	end

	result = filter_non_moving(result)

	if #result == 0 then
		return lsp_references()
	end

	if #result == 1 then
		return on_response(error, result, client)
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

--- @param opts? vim.lsp.LocationOpts
function M.definition(opts)
	internal_definition(opts, custom_on_response)
end

return M
