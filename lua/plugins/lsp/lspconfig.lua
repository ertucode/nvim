local on_attach = require("ertu.utils.lsp").on_attach

return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		-- "hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
		{
			-- jsonls icin
			"b0o/SchemaStore.nvim",
			lazy = true,
			version = false,
		},
	},
	config = function()
		local lspconfig = require("lspconfig")
		local mason_lspconfig = require("mason-lspconfig")

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				on_attach(ev.buf)
			end,
		})

		-- local completion_capabilities = require("cmp_nvim_lsp").default_capabilities()
		local completion_capabilities = require("blink.cmp").get_lsp_capabilities({}, false)
		local capabilities =
			vim.tbl_deep_extend("force", {}, vim.lsp.protocol.make_client_capabilities(), completion_capabilities)

		mason_lspconfig.setup({
			ensure_installed = {
				"vtsls",
				"html",
				"cssls",
				-- "tailwindcss",
				-- "svelte",
				"lua_ls",
				-- "graphql",
				-- "emmet_ls",
				-- "angularls",
				"jsonls",
			},
			handlers = {
				function(server_name)
					lspconfig[server_name].setup({
						capabilities = capabilities,
					})
				end,
				["ts_ls"] = function() end,
				["vtsls"] = require("plugins.lsp.lsps.vtsls")(capabilities),
				["omnisharp"] = require("plugins.lsp.lsps.omnisharp")(capabilities),
				["volar"] = require("plugins.lsp.lsps.volar")(capabilities),
				["lua_ls"] = require("plugins.lsp.lsps.lua_ls")(capabilities),
				-- ["angularls"] = require("plugins.lsp.lsps.angularls")(capabilities),
				["jsonls"] = require("plugins.lsp.lsps.jsonls")(capabilities),
			},
		})
	end,
}
