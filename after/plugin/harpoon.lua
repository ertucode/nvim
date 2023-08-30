local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>ha", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

local function nav(num)
	return function()
		ui.nav_file(num)
	end
end

vim.keymap.set("n", "<C-j>", nav(1))
vim.keymap.set("n", "<C-k>", nav(2))
vim.keymap.set("n", "<C-l>", nav(3))
vim.keymap.set("n", "<C-h>", nav(4))
