return {
	"windwp/nvim-autopairs",
	config = function()
		require("nvim-autopairs").setup({
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

		local compHandler = cmp_autopairs.on_confirm_done()
		cmp.event:on("confirm_done", function(evt)
			if evt.commit_character then
				return
			end
			local entry = evt.entry
			local filetype = vim.api.nvim_get_option_value("filetype", {
				buf = 0,
			})
			local item = entry:get_completion_item()

			-- Dont put () to typescript component function
			if
				item.kind == 2
				and filetype == "typescriptreact"
				and item.label
				and #item.label == 1
				and string.upper(item.label[1]) == item.label[1]
			then
				return
			end
			return compHandler(evt)
		end)

		local ertu = require("ertu.utils")
		vim.keymap.set({ "i", "v" }, "<C-l>", function()
			local res = ertu.get_next_char_that_is_one_of(ertu.closing_char)
			if res then
				vim.api.nvim_win_set_cursor(0, { res[1], res[2] })
			end
		end)
	end,
}
