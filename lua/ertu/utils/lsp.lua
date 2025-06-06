local M = {}

local set = vim.keymap.set -- for conciseness
function M.on_attach(buf)
	local opts = { buffer = buf, silent = true }

	set("n", "gd", function()
		require("ertu.utils.lsp_definition").definition()
	end, opts)
	set("n", "gi", function()
		vim.lsp.buf.implementation()
	end, opts)
	set("n", "gD", function()
		vim.lsp.buf.type_definition()
	end, opts)
	set("n", "<leader>lss", require("ertu.utils.typescript").go_to_source, {
		desc = "Go to source definition",
	})
	set("n", "<leader>d", function()
		vim.diagnostic.open_float()
	end, opts)
	set("n", "K", function()
		vim.lsp.buf.hover()
	end, opts)
	set("n", "<leader>lf", function()
		vim.diagnostic.open_float()
	end, opts)
	local find_highest_diag_severity = function()
		local diags = vim.diagnostic.get(0)
		if #diags == 0 then
			return
		end

		local best = diags[1].severity

		for i = 2, #diags do
			if diags[i].severity < best then
				best = diags[i].severity
			end
		end
		return vim.diagnostic.severity[best]
	end
	local best_diag = function(count)
		return function()
			vim.diagnostic.jump({
				-- severity = find_highest_diag_severity(),
				float = true,
				count = count,
				_highest = true,
			})
		end
	end
	set("n", "[d", best_diag(-1), opts)
	set("n", "]d", best_diag(1), opts)
	set("n", "<leader>ldq", function()
		local highest = find_highest_diag_severity()
		vim.diagnostic.setqflist({
			severity = highest,
		})
	end, opts)
	set({ "n", "v" }, "<leader>lac", function()
		vim.lsp.buf.code_action()
	end, opts)
	set("n", "<leader>lru", require("ertu.utils.typescript").remove_unused)
	set("n", "<leader>lai", require("ertu.utils.typescript").import_missing)
	-- set("n", "<leader>lrn", function()
	-- 	vim.api.nvim_create_autocmd({ "CmdlineEnter" }, {
	-- 		callback = function()
	-- 			local key = vim.api.nvim_replace_termcodes("<C-f>", true, false, true)
	-- 			vim.api.nvim_feedkeys(key, "c", false)
	-- 			vim.api.nvim_feedkeys("0", "n", false)
	-- 			return true
	-- 		end,
	-- 	})
	-- 	vim.lsp.buf.rename()
	-- 	-- vim.cmd("silent! wa")
	-- end, opts)
	set("i", "<C-h>", function()
		vim.lsp.buf.signature_help()
	end, opts)
	set("n", "<leader>lrs", ":LspRestart<CR>")
end

return M
