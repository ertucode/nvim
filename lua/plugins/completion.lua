--- Get completion context, i.e., auto-import/target module location.
--- Depending on the LSP this information is stored in different parts of the
--- lsp.CompletionItem payload. The process to find them is very manual: log the payloads
--- And see where useful information is stored.
---@param completion lsp.CompletionItem
---@param source cmp.Source
local function get_lsp_completion_context(completion, source)
	local _, source_name = pcall(function()
		return source.source.client.config.name
	end)
	if source_name == "tsserver" then
		return completion.detail
	elseif source_name == "pyright" or source_name == "vtsls" then
		if completion.labelDetails ~= nil then
			return completion.labelDetails.description
		end
		-- elseif source_name == "gopls" then
		-- 	return completion.detail
	end
end

local function rgb_in_docs(entry)
	local _, _, r, g, b = string.find(entry.completion_item.documentation, "^rgb%((%d+), (%d+), (%d+)")

	return r, g, b
end

local function handle_rgb_item(vim_item, r, g, b)
	local color = string.format("%02x", r) .. string.format("%02x", g) .. string.format("%02x", b)
	local group = "Tw_" .. color
	if vim.fn.hlID(group) < 1 then
		vim.api.nvim_set_hl(0, group, { fg = "#" .. color })
	end
	vim_item.kind = "■" -- or "⬤" or anything
	vim_item.kind_hl_group = group
	return vim_item
end

---@type nil | cmp.ConfigSchema
local baseOpts = nil
local function getOpts()
	local cmp = require("cmp")

	local cmp_mappings = {
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-e>"] = cmp.mapping.close(),
		["<C-y>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Replace }),
		["<C-Space>"] = cmp.mapping.complete(),
		["<Tab>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert }),
		["<C-j>"] = cmp.mapping.select_next_item(),
		["<C-k>"] = cmp.mapping.select_prev_item(),
	}

	local lspkind = require("lspkind")

	baseOpts = {
		mapping = cmp_mappings,
		view = {
			entries = {
				follow_cursor = true,
			},
		},
		sources = {
			{ name = "nvim_lsp" },
			{ name = "nvim_lua" },
			{ name = "path" },
			{ name = "luasnip" },
			-- { name = "buffer" },
		},
		snippet = {
			expand = function(args)
				require("luasnip").lsp_expand(args.body)
			end,
		},
		experimental = {
			ghost_text = {
				hl_group = "WinSeparator",
			},
		},
		performance = {
			debounce = 1,
			throttle = 1,
		},
		window = {
			documentation = cmp.config.window.bordered(),
			completion = cmp.config.window.bordered(),
		},
		formatting = {
			fields = { "kind", "abbr", "menu" },
			format = function(entry, vim_item)
				local item_with_kind = lspkind.cmp_format({
					mode = "text_symbol", -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
					maxwidth = 100, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
					menu = { -- showing type in menu
						nvim_lsp = "[LSP]",
						path = "[Path]",
						buffer = "[Buffer]",
						luasnip = "[LuaSnip]",
					},
					before = function(entry, vim_item) -- for tailwind css autocomplete
						if vim_item.kind == "Color" and entry.completion_item.documentation then
							local r, g, b = rgb_in_docs(entry)
							if r then
								return handle_rgb_item(vim_item, r, g, b)
							end
						end
						-- vim_item.kind = icons[vim_item.kind] and (icons[vim_item.kind] .. vim_item.kind) or vim_item.kind
						-- or just show the icon
						vim_item.kind = lspkind.symbolic(vim_item.kind) and lspkind.symbolic(vim_item.kind)
							or vim_item.kind
						return vim_item
					end,
				})(entry, vim_item)

				item_with_kind.menu = ""
				local completion_context = get_lsp_completion_context(entry.completion_item, entry.source)
				if completion_context ~= nil and completion_context ~= "" then
					local truncated_context = string.sub(completion_context, 1, 40)
					if truncated_context ~= completion_context then
						truncated_context = truncated_context .. "… "
					end
					item_with_kind.menu = item_with_kind.menu .. " " .. truncated_context
				end

				item_with_kind.menu_hl_group = "CmpItemAbbr"
				return item_with_kind
			end,
		},
	}
	return baseOpts
end

return {
	"hrsh7th/nvim-cmp",
	version = false,
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-buffer", -- Get completion from current file even if its not a symbol
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-nvim-lua", -- Knows nvim api
		"hrsh7th/cmp-nvim-lsp",
		"onsails/lspkind.nvim",
		"saadparwaiz1/cmp_luasnip", -- Snip and comp adapter ?
		"L3MON4D3/LuaSnip",
	},
	opts = function()
		return getOpts()
	end,

	config = function()
		local cmp = require("cmp")

		if baseOpts == nil then
			return
		end

		cmp.setup.filetype(
			{ "typescript", "typescriptreact" },
			vim.tbl_deep_extend("force", baseOpts, {
				sources = {
					{
						name = "nvim_lsp",
						entry_filter = function(entry, _)
							local detail = get_lsp_completion_context(entry.completion_item, entry.source)
							if detail == nil then
								return true
							end
							if detail == "react-day-picker" then
								return false
							end
							if string.find(detail, "radix") then
								if string.find(detail, "react-icons") then
									return true
								end
								return false
							end
							return true
						end,
					},
					{ name = "path" },
					{ name = "luasnip" },
				},
			})
		)
	end,
}
