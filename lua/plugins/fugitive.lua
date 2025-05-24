local function make_buffer_floating(target_buf_id)
	local win_ids = vim.api.nvim_list_wins()

	for _, win_id in ipairs(win_ids) do
		local buf_id = vim.api.nvim_win_get_buf(win_id)

		if buf_id == target_buf_id then
			local width = math.floor(vim.o.columns * 0.2)
			local row = 1
			local height = math.floor(vim.o.lines - row - 4)
			local col = math.floor(vim.o.columns * 0.8)

			local config = {
				relative = "editor",
				row = row,
				col = col,
				width = width,
				height = height,
				border = "single",
				style = "minimal",
			}

			vim.api.nvim_win_set_config(win_id, config)
		end
	end
end

local function autorefresh_fugitive()
	local augroup = vim.api.nvim_create_augroup("autorefresh_fugitive", {})
	local fugbuf
	vim.api.nvim_create_autocmd("User", {
		group = vim.api.nvim_create_augroup("fugitive_status_window", {}),
		pattern = "FugitiveIndex",
		callback = function(ev)
			fugbuf = ev.buf
			make_buffer_floating(fugbuf)
			vim.api.nvim_create_autocmd("BufWritePost", {
				group = augroup,
				callback = function()
					vim.api.nvim_buf_call(fugbuf, function()
						vim.fn["fugitive#BufReadStatus"](0)
					end)
				end,
			})
			vim.api.nvim_create_autocmd("BufUnload", {
				group = augroup,
				buffer = fugbuf,
				callback = function()
					vim.api.nvim_clear_autocmds({ group = augroup })
				end,
			})
		end,
	})
end

return {
	"tpope/vim-fugitive",
	cmd = { "Git", "G", "Gwrite" },
	keys = {
		{ "<leader>gt", "<cmd>Git difftool -y HEAD<CR>", desc = "Fugitive. Put all diffs to tabs" },
		{ "<leader>gl", "<cmd>Git log --oneline<CR>", desc = "Fugitive. Git log --oneline" },
		{ "<leader>gg", "<cmd>Git<CR>", desc = "Open fugitive" },
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
				local snippet = require("ertu.utils.snippet")

				snippet.put_replacable_text(git_utils.get_branch())
				vim.keymap.set({ "i", "n", "s" }, "<C-k>", "<ESC>:wq<CR>", { buffer = true, silent = true })
			end,
		})

		autorefresh_fugitive()
	end,
}
