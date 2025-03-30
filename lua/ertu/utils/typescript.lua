local M = {}

function M.remove_unused()
	local params = {
		command = "typescript.removeUnusedImports",
		arguments = { vim.api.nvim_buf_get_name(0) },
		title = "",
	}
	vim.lsp.buf.execute_command(params)
end

function M.import_missing()
	vim.lsp.buf.code_action({
		apply = true,
		context = { only = { "source.addMissingImports.ts" } },
	})
end

function M.go_to_source()
	local client = vim.lsp.get_clients({ name = "vtsls" })[1]
	if client == nil then
		print("vtsls not found")
		return
	end
	local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

	client.request("workspace/executeCommand", {
		command = "typescript.goToSourceDefinition",
		arguments = { params.textDocument.uri, params.position },
	}, function(err, result, _, _)
		if err then
			print("Go to source definition failed: " .. vim.inspect(err))
			return
		end
		if not result or vim.tbl_isempty(result) then
			print("No source definition found")
			return
		end
		vim.lsp.util.jump_to_location(result[1], "utf-8")
	end)
end

return M
