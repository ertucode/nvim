local function should_format_on_save()
	local cwd = vim.uv.cwd()
	if cwd == nil then
		return false
	end

	local paths = { "react-native/ortak", "node/bff" }
	for _, path in ipairs(paths) do
		if string.find(cwd, path, 1, true) ~= nil then
			return false
		end
	end
	return true
end

return {
	"stevearc/conform.nvim",
	event = "VeryLazy",
	config = function()
		local conform = require("conform")
		local format_on_save = should_format_on_save()
				and {
					lsp_fallback = true,
					async = false,
					timeout_ms = 1000,
				}
			or nil

		vim.keymap.set({ "n", "v" }, "<leader>mp", function()
			require("conform").format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			})
		end, { desc = "Format file or range (in visual mode)" })

		conform.setup({
			formatters_by_ft = {
				javascript = { "prettierd" },
				typescript = { "prettierd" },
				angular = { "prettierd" },
				javascriptreact = { "prettierd" },
				typescriptreact = { "prettierd" },
				svelte = { "prettierd" },
				css = { "prettierd" },
				html = { "prettierd" },
				json = { "prettierd" },
				yaml = { "prettierd" },
				markdown = { "prettierd" },
				graphql = { "prettierd" },
				liquid = { "prettierd" },
				lua = { "stylua" },
				-- python = { "isort", "black" },
			},
			format_on_save = format_on_save,
		})
	end,
}
