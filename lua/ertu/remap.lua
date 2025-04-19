vim.g.mapleader = " "
vim.g.maplocalleader = ","

local set = vim.keymap.set

-- append bottom line to current without moving the cursor
set("n", "J", "mzJ`z")

-- center cursor during jumps
set("n", "<C-d>", "<C-d>zz")
set("n", "<C-u>", "<C-u>zz")
set("n", "n", "nzzzv")
set("n", "N", "Nzzzv")

-- paste and delete without buffer
set("x", "<leader>p", [["_dP]])
-- set({ "n", "v" }, "<leader>d", [["_d]])

set("n", "x", '"_x')
set({ "n", "x" }, "c", '"_c')

-- system register
set({ "n", "v" }, "<leader>y", [["+y]])
set("v", "<C-c>", [["+y]])
set("n", "<leader>Y", [["+Y]])

set("n", "Q", "<nop>")
set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

set("n", "<leader>uu", "<cmd>:source ~/.config/nvim/git.lua<CR>", { desc = "Source file" })

set("n", "<leader>xx", "<cmd>!chmod +x %<CR>", { silent = true })
-- set("n", "<leader><leader>k", ":w<CR> :so %<CR>")
--
-- set("n", "<leader><leader>", function()
-- 	vim.cmd("so")
-- end)

-- increment decrement
set("n", "<leader>+", "<C-a>")
set("n", "<leader>-", "<C-x>")

set("n", "<leader>cl", "$a)<esc>_iconsole.log(<esc>_")

-- steals from folke
-- set("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
-- set("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
-- set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
-- set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
-- set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
-- set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

-- better indenting
set("v", "<", "<gv")
set("v", ">", ">gv")

-- paste with format
set("n", "<M-p>", "p'[v']=", { desc = "Paste with format" })
set("n", "<leader>sp", [["*p'[v']=]], { desc = "Paste from system clipboard" })
set("n", "gp", "'[V']", { desc = "Highlight last paste line visual" })
set("n", "gP", "'[v']", { desc = "Highlight last paste visual" })

-- quickfix list
set("n", "<leader>qc", ":cclose<CR>")
set("n", "<leader>qo", ":copen<CR>")
set("n", "]q", ":cnext<CR>")
set("n", "[q", ":cprev<CR>")

-- This kemap makes it possible to exit the command-window (:h cmdwin)
-- with <ESC>
vim.api.nvim_create_autocmd({ "CmdwinEnter" }, {
	callback = function()
		vim.keymap.set("n", "<esc>", ":quit<CR>", { buffer = true })
	end,
})

set({ "i", "n" }, "<C-m>", ":cclose<CR>")

set("n", "<F2>", ":qa!<CR>")

set("i", "<C-l>", "<ESC>")

set("n", "<leader>oc", ":silent !code .<CR>")

set("n", "♦", function()
	print("heree")
	local str = require("ertu.utils.misc").get_string_under_cursor()
	if str == "" or str == nil then
		return
	end
	vim.fn.setreg("+", str)
end, {
	desc = "Copy string under cursor to system clipboard",
})

set("n", "♣", function()
	print("here")
	local clipboard_contents = vim.fn.getreg("+")

	if clipboard_contents:find("\n") then
		print("Clipboard has new line")
		return
	end

	require("ertu.utils.misc").replace_string_under_cursor(clipboard_contents)
end, {
	desc = "Replace string under cursor with system clipboard",
})

set("n", "n", ":keepjumps normal! n<cr>", { desc = "n but don't change jump list" })
set("n", "N", ":keepjumps normal! N<cr>", { desc = "N but don't change jump list" })
