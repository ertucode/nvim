return function(capabilities)
	return function()
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
						autoImportFileExcludePatterns = { "@radix-ui/*", "react-day-picker" },
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
	end
end
