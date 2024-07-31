return {
	"mg979/vim-visual-multi",
	config = function()
		--   vim.keymap.set("n", "<M-j>", "<Plug>(VM-Find-Under)")
		--   vim.keymap.set("n", "<M-j>", "<Plug>(VM-Find-Subword-Under)")
		--   https://github.com/mg979/vim-visual-multi/blob/master/autoload/vm/maps/all.vim
	end,
	init = function()
		vim.g.VM_maps = {
			["Find Under"] = "<M-j>",
			["Find Subword Under"] = "<M-j>",
			["Case Conversion Menu"] = "<M-k>",
		}
	end,
}
