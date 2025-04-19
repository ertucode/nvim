return {
	"tpope/vim-fugitive",
	command = "Git",
	config = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "fugitive",
			callback = function()
				vim.keymap.set("n", "S", ":Git add .<CR>", { buffer = true, silent = true })
				vim.keymap.set("n", "P", ":Git push<CR>", { buffer = true, silent = true })

				vim.api.nvim_command("normal! 5G")
			end,
		})
	end,
}
