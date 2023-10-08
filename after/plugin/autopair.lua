local status_ok, npairs = pcall(require, "nvim-autopairs")
if not status_ok then
	return
end

npairs.setup({
	check_ts = true,
	ts_config = {
		lua = { "string", "source" },
		javascript = { "string", "template_string" },
	},
	disable_filetype = { "TelescopePrompt" },
	fast_wrap = {
		map = "<M-e>",
		chars = { "{", "[", "(", '"', "'" },
		pattern = [=[[%'%"%>%]%)%}%,]]=],
		end_key = "$",
		keys = "qwertyuiopzxcvbnmasdfghjkl",
		check_comma = true,
		manual_position = true,
		highlight = "Search",
		highlight_grey = "Comment",
	},
})

local cmp_autopairs = require("nvim-autopairs.completion.cmp")
local cmp = require("cmp")

cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

local ertu = require("ertu.utils")
vim.keymap.set({ "i", "v" }, "<C-l>", function()
	local res = ertu.get_next_char_that_is_one_of(ertu.closing_char)
	if res then
		vim.api.nvim_win_set_cursor(0, { res[1], res[2] })
	end
end)
