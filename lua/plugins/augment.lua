return {
	"augmentcode/augment.vim",
	init = function()
		vim.g.augment_disable_tab_mapping = true
	end,
	config = function()
		vim.keymap.set("i", "<M-n>", "<cmd>call augment#Accept()<cr>")
	end,
	enabled = false,
}
