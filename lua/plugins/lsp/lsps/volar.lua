return function(capabilities)
	return function()
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
	end
end
