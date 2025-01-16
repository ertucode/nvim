-- https://github.com/typescript-language-server/typescript-language-server/issues/216
-- http://www.lazyvim.org/extras/lang/typescript TODO

local on_attach = require("ertu.utils.lsp").on_attach

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

local function filterReactDTS(value)
	local uri = value.uri or value.targetUri
	return string.match(uri, "react/index.d.ts") == nil
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

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Doing this breaks gd?
				--[[ local client = vim.lsp.get_client_by_id(ev.data.client_id)
				if client and client.name == "vtsls" and is_angular_project() then
					vim.lsp.stop_client({ ev.data.client_id })
					return
				end ]]
				on_attach(ev.buf)
			end,
		})

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = vim.tbl_deep_extend(
			-- "error": raise an error
			-- "keep": use value from the leftmost map
			-- "force": use value from the rightmost map
			"force",
			{}, -- Empty capabilities
			vim.lsp.protocol.make_client_capabilities(), -- Minimal capabilities
			require("cmp_nvim_lsp").default_capabilities() -- Default capabilities
		)

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
			-- ["tsserver"] = function()
			-- require("lspconfig").tsserver.setup({
			-- 	capabilities = capabilities,
			-- })
			-- end,
			["ts_ls"] = function()
				-- require("lspconfig").ts_ls.setup({
				-- 	capabilities = capabilities,
				-- })
			end,
			["vtsls"] = function()
				-- return
				require("lspconfig").vtsls.setup({
					capabilities = capabilities,
					inlay_hints = { enabled = true },
					root_dir = function(fname)
						if string.find(fname, "react-native") then
							return vim.fs.root(fname, "package.json")
						end

						return vim.uv.cwd()
					end,
					settings = {
						typescript = {
							preferences = {
								autoImportFileExcludePatterns = { "@radix-ui/*" },
								--[[importModuleSpecifierPreference [string] Supported values: 'shortest', 'project-relative', 'relative', 'non-relative'. Default: 'shortest']]
							},
							inlayHints = {
								includeInlayParameterNameHints = "all",
								includeInlayParameterNameHintsWhenArgumentMatchesName = true,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayVariableTypeHintsWhenTypeMatchesName = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
						},
					},
				})
			end,
			["omnisharp"] = function()
				lspconfig.omnisharp.setup({
					capabilities = capabilities,
					cmd = { "dotnet", vim.fn.stdpath("data") .. "/mason/packages/omnisharp/libexec/OmniSharp.dll" },
					enable_import_completion = true,
					organize_imports_on_format = true,
					enable_roslyn_analyzers = true,
					root_dir = function()
						return vim.loop.cwd() -- current working directory
					end,
				})
			end,
			["volar"] = function()
				require("lspconfig").volar.setup({
					capabilities = capabilities,
					init_options = {
						vue = {
							hybridMode = false,
						},
						typescript = {
							tsdk = require("mason-registry").get_package("vue-language-server"):get_install_path()
								.. "/node_modules/typescript/lib",
						},
					},
					settings = {
						typescript = {
							inlayHints = {
								enumMemberValues = {
									enabled = true,
								},
								functionLikeReturnTypes = {
									enabled = true,
								},
								propertyDeclarationTypes = {
									enabled = true,
								},
								parameterTypes = {
									enabled = true,
									suppressWhenArgumentMatchesName = true,
								},
								variableTypes = {
									enabled = true,
								},
							},
						},
					},
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
			["angularls"] = function()
				local ok, mason_registry = pcall(require, "mason-registry")
				if not ok then
					vim.notify("mason-registry could not be loaded")
					return
				end

				local angularls_path = mason_registry.get_package("angular-language-server"):get_install_path()

				local cmd = {
					"ngserver",
					"--stdio",
					"--tsProbeLocations",
					table.concat({
						angularls_path,
						vim.uv.cwd(),
					}, ","),
					"--ngProbeLocations",
					table.concat({
						angularls_path .. "/node_modules/@angular/language-server",
						vim.uv.cwd(),
					}, ","),
				}

				local config = {
					cmd = cmd,
					on_new_config = function(new_config, new_root_dir)
						new_config.cmd = cmd
					end,
				}

				lspconfig["angularls"].setup(config)
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

		local initial_definition_handler = vim.lsp.handlers["textDocument/definition"]
		vim.lsp.handlers["textDocument/definition"] = function(err, result, ctx, config)
			local clientId = ctx.client_id
			local client = vim.lsp.get_client_by_id(clientId)
			if client == nil then
				return
			end
			if not (client.name == "tsserver" or client.name == "vtsls" or client.name == "ts_ls") then
				initial_definition_handler(err, result, ctx, config)
				return
			end

			if vim.islist(result) and #result > 1 then
				print(vim.inspect(ctx))
				local filtered = filter(result, filterReactDTS)
				if #filtered > 1 then
					require("telescope.builtin").lsp_definitions()
				else
					initial_definition_handler(err, filtered, ctx, config)
				end
				return
			end

			return initial_definition_handler(err, result, ctx, config)
		end
	end,
}
