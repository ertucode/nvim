local function add_missing_imports(bufnr)
	-- https://github.com/jose-elias-alvarez/typescript.nvim/blob/4de85ef699d7e6010528dcfbddc2ed4c2c421467/lua/typescript/source-actions.lua#L38
	-- https://github.com/typescript-language-server/typescript-language-server
	local client = vim.lsp.get_active_clients({ bufnr = bufnr, name = "tsserver" })[1]
	if not client then
		return
	end

	local params = vim.tbl_extend("force", vim.lsp.util.make_range_params(), {
		context = {
			only = { "source.addMissingImports.ts" },
			diagnostics = vim.diagnostic.get(bufnr),
		},
	})

	local function applyEdits(res)
		if
			res[1]
			and res[1].edit
			and res[1].edit.documentChanges
			and res[1].edit.documentChanges[1]
			and res[1].edit.documentChanges[1].edits
		then
			vim.lsp.util.apply_text_edits(res[1].edit.documentChanges[1].edits, bufnr, client.offset_encoding)
		end
	end

	client.request("textDocument/codeAction", params, function(_, res)
		return applyEdits(res or {})
	end, bufnr)
end

return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		-- import lspconfig plugin
		local lspconfig = require("lspconfig")

		-- import mason_lspconfig plugin
		local mason_lspconfig = require("mason-lspconfig")

		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local set = vim.keymap.set -- for conciseness

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local opts = { buffer = ev.buf, silent = true }

				set("n", "gd", function()
					vim.lsp.buf.definition()
				end, opts)
				set("n", "gD", function()
					vim.lsp.buf.type_definition()
				end, opts)
				set("n", "<leader>d", function()
					vim.diagnostic.open_float()
				end, opts)
				set("n", "K", function()
					vim.lsp.buf.hover()
				end, opts)
				set("n", "<leader>lf", function()
					vim.diagnostic.open_float()
				end, opts)
				set("n", "[d", function()
					vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
				end, opts)
				set("n", "]d", function()
					vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
				end, opts)
				set("n", "<leader>lac", function()
					vim.lsp.buf.code_action()
				end, opts)
				set("n", "<leader>lrn", function()
					vim.lsp.buf.rename()
					vim.wait(50, function()
						vim.cmd("silent! wa")
					end)
				end, opts)
				set("i", "<C-h>", function()
					vim.lsp.buf.signature_help()
				end, opts)
				set("n", "<leader>lru", function()
					local params = {
						command = "_typescript.organizeImports",
						arguments = { vim.api.nvim_buf_get_name(ev.buf) },
						title = "",
					}
					vim.lsp.buf_request_sync(ev.buf, "workspace/executeCommand", params)
				end)
				set("n", "<leader>lrs", ":LspRestart<CR>")
				set("n", "<leader>lai", function()
					add_missing_imports(ev.buf)
				end)
			end,
		})

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Change the Diagnostic symbols in the sign column (gutter)
		-- (not in youtube nvim video)
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		mason_lspconfig.setup_handlers({
			-- default handler for installed servers
			function(server_name)
				lspconfig[server_name].setup({
					capabilities = capabilities,
				})
			end,
			-- ["svelte"] = function()
			-- 	-- configure svelte server
			-- 	lspconfig["svelte"].setup({
			-- 		capabilities = capabilities,
			-- 		on_attach = function(client, bufnr)
			-- 			vim.api.nvim_create_autocmd("BufWritePost", {
			-- 				pattern = { "*.js", "*.ts" },
			-- 				callback = function(ctx)
			-- 					-- Here use ctx.match instead of ctx.file
			-- 					client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
			-- 				end,
			-- 			})
			-- 		end,
			-- 	})
			-- end,
			-- ["graphql"] = function()
			-- 	-- configure graphql language server
			-- 	lspconfig["graphql"].setup({
			-- 		capabilities = capabilities,
			-- 		filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
			-- 	})
			-- end,
			["emmet_ls"] = function()
				-- configure emmet language server
				lspconfig["emmet_ls"].setup({
					capabilities = capabilities,
					filetypes = {
						"html",
						"typescriptreact",
						"javascriptreact",
						"css",
						"sass",
						"scss",
						"less",
						"svelte",
					},
				})
			end,
			["lua_ls"] = function()
				-- configure lua server (with special settings)
				lspconfig["lua_ls"].setup({
					capabilities = capabilities,
					settings = {
						Lua = {
							runtime = {
								version = "LuaJIT",
								path = vim.split(package.path, ";"),
							},
							diagnostics = {
								globals = { "vim" },
								disable = {
									"trailing-space",
								},
							},
							workspace = {
								library = {
									[vim.fn.expand("$VIMRUNTIME/lua")] = true,
									[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
								},
							},
						},
					},
				})
			end,
			-- lsp.configure("jsonls", {
			-- 	settings = {
			-- 		json = {
			-- 			schemas = {
			-- 				{
			-- 					fileMatch = { "package.json" },
			-- 					url = "https://json.schemastore.org/package.json",
			-- 				},
			-- 				{
			-- 					fileMatch = { "tsconfig*.json" },
			-- 					url = "https://json.schemastore.org/tsconfig.json",
			-- 				},
			-- 				{
			-- 					fileMatch = {
			-- 						".prettierrc",
			-- 						".prettierrc.json",
			-- 						"prettier.config.json",
			-- 					},
			-- 					url = "https://json.schemastore.org/prettierrc.json",
			-- 				},
			-- 			},
			-- 		},
			-- 	},
			-- })
		})
	end,
}