vim.g.mapleader = " "

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
set({ "n", "v" }, "<leader>d", [["_d]])

set("n", "x", '"_x')
set({ "n", "x" }, "c", '"_c')

-- system register
set({ "n", "v" }, "<leader>y", [["+y]])
set("n", "<leader>Y", [["+Y]])

set("n", "Q", "<nop>")
set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
set("n", "<leader>f", vim.lsp.buf.format)

-- change the word on the cursor
set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

set("n", "<leader>xx", "<cmd>!chmod +x %<CR>", { silent = true })
set("n", "<leader><leader>k", ":w<CR> :so %<CR>")

set("n", "<leader><leader>", function()
	vim.cmd("so")
end)

-- increment decrement
set("n", "<leader>+", "<C-a>")
set("n", "<leader>-", "<C-x>")

set("n", "<leader>cl", "$a)<esc>_iconsole.log(<esc>_")

-- steals from folke
set("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
set("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

-- better indenting
set("v", "<", "<gv")
set("v", ">", ">gv")
