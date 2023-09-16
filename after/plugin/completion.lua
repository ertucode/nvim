local lsp = require("lsp-zero")

local cmp = require("cmp")

local cmp_mappings = lsp.defaults.cmp_mappings({
	["<C-d"] = cmp.mapping.scroll_docs(-4),
	["<C-f"] = cmp.mapping.scroll_docs(4),
	["<C-e"] = cmp.mapping.close(),
	["<C-y>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert }),
	["<C-Space>"] = cmp.mapping.complete(),
	["<Tab>"] = function(fallback)
		if cmp.visible() then
			cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert })
		else
			fallback()
		end
	end,
})

local lspkind = require("lspkind")

cmp.setup({
	mapping = cmp_mappings,
	sources = {
		{ name = "nvim_lua" },
		{ name = "nvim_lsp" },
		{ name = "path" },
		{ name = "luasnip" },
		{ name = "buffer", keyword_length = 1 },
	},
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	experimental = {
		ghost_text = true,
	},
	window = {
		documentation = cmp.config.enable,
	},
	formatting = {
		fields = { "kind", "abbr", "menu" },
		format = lspkind.cmp_format({
			mode = "symbol_text", -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
			maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
			menu = { -- showing type in menu
				nvim_lsp = "[LSP]",
				path = "[Path]",
				buffer = "[Buffer]",
				luasnip = "[LuaSnip]",
			},
			before = function(entry, vim_item) -- for tailwind css autocomplete
				if vim_item.kind == "Color" and entry.completion_item.documentation then
					local _, _, r, g, b = string.find(entry.completion_item.documentation, "^rgb%((%d+), (%d+), (%d+)")
					if r then
						local color = string.format("%02x", r) .. string.format("%02x", g) .. string.format("%02x", b)
						local group = "Tw_" .. color
						if vim.fn.hlID(group) < 1 then
							vim.api.nvim_set_hl(0, group, { fg = "#" .. color })
						end
						vim_item.kind = "■" -- or "⬤" or anything
						vim_item.kind_hl_group = group
						return vim_item
					end
				end
				-- vim_item.kind = icons[vim_item.kind] and (icons[vim_item.kind] .. vim_item.kind) or vim_item.kind
				-- or just show the icon
				vim_item.kind = lspkind.symbolic(vim_item.kind) and lspkind.symbolic(vim_item.kind) or vim_item.kind
				return vim_item
			end,
		}),
	},
})

lsp.setup_nvim_cmp({
	mapping = cmp_mappings,
})
