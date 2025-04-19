return {
	"tpope/vim-fugitive",
	command = "Git",
	config = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "fugitive",
			callback = function()
				vim.keymap.set("n", "S", ":Git add .<CR>", { buffer = true, silent = true })
				vim.keymap.set("n", "P", function()
					vim.api.nvim_command("Git push<CR>")
					vim.api.nvim_command("q<CR>")
				end, { buffer = true, silent = true })

				vim.api.nvim_command("normal! 5G")
			end,
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "gitcommit",
			callback = function()
				vim.api.nvim_command("startinsert")
			end,
		})
	end,
}
