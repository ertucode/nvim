local status, oil = pcall(require, "oil")

if not status then
	return
end

oil.setup({
	keymaps = {
		["<C-p>"] = false,
	},
})

vim.keymap.set("n", "-", require("oil").open, { desc = "Open parent directory" })
