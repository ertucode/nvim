return {
	"tpope/vim-fugitive",
	cmd = { "Git", "G", "Gwrite" },
	keys = {
		{ "<leader>gt", "<cmd>Git difftool -y HEAD<CR>", desc = "Fugitive. Put all diffs to tabs" },
		{ "<leader>gl", "<cmd>Git log --oneline<CR>", desc = "Fugitive. Git log --oneline" },
	},
	config = function()
		local augroup = vim.api.nvim_create_augroup("Fugitive", { clear = true })
		vim.api.nvim_create_autocmd("FileType", {
			group = augroup,
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
			group = augroup,
			pattern = "gitcommit",
			callback = function()
				local git_utils = require("ertu.utils.git")
				local ls = require("luasnip")
				local s = ls.snippet
				local i = ls.insert_node
				local fmt = require("luasnip.extras.fmt").fmt

				ls.snip_expand(s(
					"autocommit",
					fmt("{}", {
						i(1, git_utils.get_branch(), nil),
					})
				))
				vim.keymap.set({ "i", "n", "s" }, "<C-k>", "<ESC>:wq<CR>", { buffer = true, silent = true })
			end,
		})
	end,
}
