local function nav(num)
	return function()
		require("harpoon.ui").nav_file(num)
	end
end

return {
	"theprimeagen/harpoon",
	keys = {
		{ "<C-j>", nav(1) },
		{ "<C-k>", nav(2) },
		{ "<C-l>", nav(3) },
		{ "<C-h>", nav(4) },
		{ "<leader><C-j>", nav(5) },
		{ "<leader><C-k>", nav(6) },
		{ "<leader><C-l>", nav(7) },
		{ "<leader><C-h>", nav(8) },
		{
			"<leader>ha",
			function()
				require("harpoon.mark").add_file()
			end,
		},
		{
			"<C-e>",
			function()
				require("harpoon.ui").toggle_quick_menu()
			end,
		},
	},
	config = function() end,
}
