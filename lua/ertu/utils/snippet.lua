local M = {}

function M.put_replacable_text(text)
	local ls = require("luasnip")
	local s = ls.snippet
	local i = ls.insert_node
	local fmt = require("luasnip.extras.fmt").fmt

	ls.snip_expand(s(
		"randomname",
		fmt("{}", {
			i(1, text, nil),
		})
	))
end

return M
