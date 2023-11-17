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
		vim.diagnostic.goto_next({
			severity = vim.diagnostic.severity.ERROR,
		})
	end, opts)
	vim.keymap.set("n", "]d", function()
		vim.diagnostic.goto_prev({
			severity = vim.diagnostic.severity.ERROR,
		})
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

	vim.keymap.set("n", "<leader>lai", function()
		add_missing_imports(bufnr)
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

local diag_config = {
	virtual_text = false,
	underline = true,
	update_in_insert = true,
}

vim.diagnostic.config(diag_config)

vim.keymap.set("n", "<leader>lds", function()
	diag_config.virtual_text = true
	vim.diagnostic.config(diag_config)
end)

vim.keymap.set("n", "<leader>ldh", function()
	diag_config.virtual_text = false
	vim.diagnostic.config(diag_config)
end)
