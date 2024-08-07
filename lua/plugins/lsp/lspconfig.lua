-- https://github.com/typescript-language-server/typescript-language-server/issues/216
-- http://www.lazyvim.org/extras/lang/typescript TODO

local function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

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
				set("n", "gi", function()
					vim.lsp.buf.implementation()
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
				local best_diag = function(goer)
					return function()
						local highest = find_highest_diag_severity()
						goer({ severity = highest })
					end
				end
				set("n", "[d", function()
					if require("ertu.utils").qf.is_opened() then
						local success = pcall(function()
							vim.cmd("cprev")
						end)
						if not success then
							pcall(function()
								vim.cmd("clast")
							end)
						end
					else
						best_diag(vim.diagnostic.goto_prev)()
					end
				end, opts)
				set("n", "]d", function()
					if require("ertu.utils").qf.is_opened() then
						local success = pcall(function()
							vim.cmd("cnext")
						end)
						if not success then
							pcall(function()
								vim.cmd("cfirst")
							end)
						end
					else
						best_diag(vim.diagnostic.goto_next)()
					end
				end, opts)
				set("n", "<leader>ldq", function()
					local highest = find_highest_diag_severity()
					vim.diagnostic.setqflist({
						severity = highest,
					})
				end, opts)
				set({ "n", "v" }, "<leader>lac", function()
					vim.lsp.buf.code_action()
				end, opts)
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
				set("n", "<leader>lrn", ":Lspsaga rename<CR>")
				set("i", "<C-h>", function()
					vim.lsp.buf.signature_help()
				end, opts)
				set("n", "<leader>lrs", ":LspRestart<CR>")
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
			if client.name ~= "tsserver" then
				initial_definition_handler(err, result, ctx, config)
				return
			end

			if vim.islist(result) and #result > 1 then
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
