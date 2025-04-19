return {
	"tpope/vim-fugitive",
	cmd = { "Git", "G" },
	keys = {
		{ "<leader>gt", "<cmd>Git difftool -y<CR>", desc = "Fugitive. Put all diffs to tabs" },
	},
	config = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "fugitive",
			callback = function()
				vim.keymap.set("n", "S", ":Git add .<CR>", { buffer = true, silent = true })
				vim.keymap.set("n", "P", function()
					vim.cmd("Git push")
					vim.cmd("quit")
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
