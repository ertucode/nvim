local status, lsp = pcall(require, "lsp-zero")

if not status then
	return
end

lsp.preset("recommended")

lsp.configure("lua_ls", {
	cmd = { "lua-language-server" },
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

lsp.set_preferences({
	sign_icons = {
		error = "E",
		warn = "W",
		hint = "H",
		info = "I",
	},
})

lsp.on_attach(function(_, bufnr)
	local opts = { buffer = bufnr, remap = false }

	vim.keymap.set("n", "gd", function()
		vim.lsp.buf.definition()
	end, opts)
	vim.keymap.set("n", "gD", function()
		vim.lsp.buf.type_definition()
	end, opts)
	vim.keymap.set("n", "K", function()
		vim.lsp.buf.hover()
	end, opts)
	vim.keymap.set("n", "<leader>lf", function()
		vim.diagnostic.open_float()
	end, opts)
	vim.keymap.set("n", "[d", function()
		vim.diagnostic.goto_next()
	end, opts)
	vim.keymap.set("n", "]d", function()
		vim.diagnostic.goto_prev()
	end, opts)
	vim.keymap.set("n", "<leader>lac", function()
		vim.lsp.buf.code_action()
	end, opts)
	vim.keymap.set("n", "<leader>lrn", function()
		vim.lsp.buf.rename()
		vim.wait(50, function()
			vim.cmd("silent! wa")
		end)
	end, opts)
	vim.keymap.set("i", "<C-h>", function()
		vim.lsp.buf.signature_help()
	end, opts)

	vim.keymap.set("n", "<leader>lru", function()
		local params = {
			command = "_typescript.organizeImports",
			arguments = { vim.api.nvim_buf_get_name(bufnr) },
			title = "",
		}

		vim.lsp.buf_request_sync(bufnr, "workspace/executeCommand", params)
	end)
end)

lsp.configure("jsonls", {
	settings = {
		json = {
			schemas = {
				{
					fileMatch = { "package.json" },
					url = "https://json.schemastore.org/package.json",
				},
				{
					fileMatch = { "tsconfig*.json" },
					url = "https://json.schemastore.org/tsconfig.json",
				},
				{
					fileMatch = {
						".prettierrc",
						".prettierrc.json",
						"prettier.config.json",
					},
					url = "https://json.schemastore.org/prettierrc.json",
				},
			},
		},
	},
})

lsp.configure("emmet_language_server", {
	filetypes = {
		"css",
		"eruby",
		"html",
		"javascript",
		"javascriptreact",
		"less",
		"sass",
		"scss",
		"svelte",
		"pug",
		"typescriptreact",
		"vue",
	},
	init_options = {
		--- @type table<string, any> https://docs.emmet.io/customization/preferences/
		preferences = {},
		--- @type "always" | "never" defaults to `"always"`
		showexpandedabbreviation = "always",
		--- @type boolean defaults to `true`
		showabbreviationsuggestions = true,
		--- @type boolean defaults to `false`
		showsuggestionsassnippets = false,
		--- @type table<string, any> https://docs.emmet.io/customization/syntax-profiles/
		syntaxprofiles = {},
		--- @type table<string, string> https://docs.emmet.io/customization/snippets/#variables
		variables = {},
		--- @type string[]
		excludelanguages = {},
	},
})

lsp.setup()

vim.diagnostic.config({
	virtual_text = true,
})
