---@class FileToDiff
---@field filename string
---@field in_split boolean

---Detect if we are in a fugitive diff split view
---@param direction "next"|"prev" Direction for navigation (unused, reserved for future)
---@return boolean
local function is_in_split_view(direction)
	local wins = vim.api.nvim_list_wins()
	local current_win = vim.api.nvim_get_current_win()
	local current_buf = vim.api.nvim_win_get_buf(current_win)
	local current_ft = vim.bo[current_buf].filetype

	-- Check if current window is a fugitive status buffer
	if current_ft ~= "fugitive" then
		return false
	end

	-- Count windows with diff mode enabled
	local diff_wins = 0
	local has_fugitive_diff = false

	for _, win in ipairs(wins) do
		if vim.wo[win].diff then
			diff_wins = diff_wins + 1
			local buf = vim.api.nvim_win_get_buf(win)
			local bufname = vim.api.nvim_buf_get_name(buf)
			-- Check if this is a fugitive diff buffer
			if bufname:match("^fugitive://") then
				has_fugitive_diff = true
			end
		end
	end

	-- We're in a split view if there are multiple diff windows
	-- and at least one is a fugitive diff
	return diff_wins >= 2 and has_fugitive_diff
end

---Get the file to open diff for, considering split view state
---@param direction "next"|"prev" Direction to navigate for next file
---@return FileToDiff|nil FileToDiff table with filename and in_split flag, or nil if not found
local function find_file_open_diff_for(direction)
	local in_split = is_in_split_view(direction)
	local git = require("ertu.utils.git")

	-- Get filename from current buffer (not cursor)
	local current_buf = vim.api.nvim_get_current_buf()
	local bufname = vim.api.nvim_buf_get_name(current_buf)
	-- Extract filename from fugitive://path/.git//0/path/to/file -> path/to/file
	local current_filename = bufname:match("^fugitive://.+/.git//%d+/(.+)$") or bufname

	-- Get list of changed files
	local changed_files = git.get_changed_files()
	if #changed_files == 0 then
		return nil
	end

	-- Find current file index in changed_files list
	local current_idx = nil
	for i, file in ipairs(changed_files) do
		if file.name == current_filename then
			current_idx = i
			break
		end
	end

	-- If current file not in changed files, return nil
	if not current_idx then
		current_idx = 1
	end

	local target_idx
	if direction == "next" then
		target_idx = (current_idx % #changed_files) + 1
	else
		target_idx = current_idx - 1
		if target_idx < 1 then
			target_idx = #changed_files
		end
	end

	return { filename = changed_files[target_idx].name, in_split = in_split }
end

---Navigate to the next changed file and open Gdiffsplit
---@param direction "next"|"prev" Direction to navigate
local function navigate_to_new_change_file(direction)
	local result = find_file_open_diff_for(direction)

	if not result then
		vim.notify("No changed files found", vim.log.levels.WARN)
		return
	end

	-- Navigate to the file
	vim.cmd("edit " .. result.filename)
	-- Run Gdiffsplit on it
	vim.cmd("Gdiffsplit")
end

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

local function only_except_fugitive()
	local current = vim.api.nvim_get_current_win()

	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if win ~= current then
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.bo[buf].filetype ~= "fugitive" then
				vim.api.nvim_win_close(win, false)
			end
		end
	end
end

-- vim.fn.getqflist({ context = 1, idx = 1 }).context.items[1].diff[1]
-- {
--   filename = "fugitive:///Users/cavitertugrulsirt/.config/nvim/.git//0/dotfiles/helpers.zshrc",
--   lnum = "15",
--   module = ":0:dotfiles/helpers.zshrc",
--   text = "alias koda='function _koda() { open -a koda --args --initial-path=\"$(cd \"$1\" 2>/",
--   valid = 1
-- }

return {
	"tpope/vim-fugitive",
	cmd = { "Git", "G", "Gwrite" },
	keys = {
		{ "<leader>gt", "<cmd>Git difftool -y HEAD<CR>", desc = "Fugitive. Put all diffs to tabs" },
		{ "<leader>gl", "<cmd>Git log --oneline<CR>", desc = "Fugitive. Git log --oneline" },
		{ "<leader>go", only_except_fugitive, desc = "Only window except Fugitive" },
		{ "<leader>gg", "<cmd>Git<CR>", desc = "Open fugitive" },
		{ "ɷ", "<cmd>Git<CR>", desc = "Open fugitive" },
		{
			"[f",
			function()
				navigate_to_new_change_file("prev")
			end,
			desc = "Navigate to previous changed file",
		},
		{
			"]f",
			function()
				navigate_to_new_change_file("next")
			end,
			desc = "Navigate to next changed file",
		},
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

				vim.keymap.set("n", "q", ":q<CR>", { buffer = true, silent = true })

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
