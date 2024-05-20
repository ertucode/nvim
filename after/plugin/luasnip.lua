local status, ls = pcall(require, "luasnip")

if not status then
	return
end

local types = require("luasnip.util.types")

ls.config.set_config({
	history = true,

	updateevents = "TextChanged,TextChangedI",

	enable_autosnippets = true,

	ext_opts = {
		[types.choiceNode] = {
			active = {
				virt_text = { { "<-", "Error" } },
			},
		},
	},
})

local ertu = require("ertu.utils")

local mappings = vim.api.nvim_get_keymap("i")
local prev_k_mapping = ertu.find_mapping(mappings, "<C-L>") -- Buyuk L onemli

vim.keymap.set({ "i", "s" }, "<C-l>", function()
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	else
		if prev_k_mapping then
			prev_k_mapping.callback()
		end
	end
end, { silent = true })

-- <c-j> is my jump backwards key.
-- this always moves to the previous item within the snippet
vim.keymap.set({ "i", "s" }, "<c-j>", function()
	if ls.jumpable(-1) then
		ls.jump(-1)
	end
end, { silent = true })

-- <c-l> is selecting within a list of options.
-- This is useful for choice nodes (introduced in the forthcoming episode 2)
vim.keymap.set("i", "<c-k>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end)

-- shorcut to source my luasnips file again, which will reload my snippets
vim.keymap.set("n", "<leader><leader>s", "<cmd>source ~/.config/nvim/after/plugin/luasnip.lua<CR>")

require("luasnip.loaders.from_vscode").lazy_load()

local s = ls.s
local fmt = require("luasnip.extras.fmt").fmt
local i = ls.insert_node
local rep = require("luasnip.extras").rep
local t = ls.text_node
local c = ls.choice_node
local f = ls.function_node

ls.add_snippets("lua", {
	ls.parser.parse_snippet("lf", "local $1 = function($2)\n  $0\nend"),
	s("req", fmt("local {} = require('{}')", { i(1, "default_val"), rep(1) })),
})

ls.add_snippets("rust", {
	s(
		"modtest",
		fmt(
			[[
                #[cfg(test)]
                mod test {{
                {}

                    {}
                }}
            ]],
			{
				c(1, { t("    use super::*;"), t("") }),
				i(0),
			}
		)
	),
})

ls.add_snippets("all", {
	s(
		"curtime",
		f(function()
			return os.date("%D - %H:%M")
		end)
	),
})

local stringUtils = require("ertu.utils.string")

local ngCompName = function(snip)
	return vim.split(snip.env.TM_FILENAME, ".", { plain = true })[1]
end

local filename = function()
	return f(function(_, snip)
		return ngCompName(snip)
	end)
end

local function componentNameFn(args, snip)
	local wholeName = args[1][1] .. "-" .. ngCompName(snip)
	return stringUtils.camelToCapital(wholeName)
end

ls.add_snippets("typescript", {
	s(
		"comp",
		fmt(
			[[
import {{ CommonModule }} from "@angular/common"
import {{ Component }} from "@angular/core"
import {{ LocalizationModule }} from "@sipaywalletgate/ngx-sipay/localization"

@Component({{
  selector: "{}{}",
  imports: [LocalizationModule, CommonModule],
  styleUrls: ["./{}.component.scss"],
  templateUrl: "./{}.component.html",
  standalone: true,
}})
export class {}Component {{
  {}
}}
            ]],
			{
				i(1),
				filename(),
				filename(),
				filename(),
				f(componentNameFn, { 1 }),
				i(0),
			}
		)
	),
})

ls.add_snippets("html", {
	s(
		"ng-localize",
		fmt(
			[[<ng-container *localize="let t">
  {}
</ng-container>
            ]],
			{
				i(0),
			}
		)
	),
})

ls.add_snippets("oil", {
	s(
		"comp",
		fmt(
			[[
    {}.component.ts
    {}.component.scss
    {}.component.html
    ]],
			{
				i(1),
				rep(1),
				rep(1),
			}
		)
	),
})

ls.add_snippets("oil", {
	s(
		"cf",
		fmt(
			[[
    {}/{}.component.ts
    {}/{}.component.scss
    {}/{}.component.html
    ]],
			{
				i(1),
				rep(1),
				rep(1),
				rep(1),
				rep(1),
				rep(1),
			}
		)
	),
})
