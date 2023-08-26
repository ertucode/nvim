vim.g.mapleader = " "

local set = vim.keymap.set

-- vs code alt-arrow
local j = ":m '>+1<CR>gv=gv"
local k = ":m '<-2<CR>gv=gv"

set("v", "<M-j>", j)
set("v", "<M-k>", k)

set("i", "<M-j>", "<esc>v" .. j .. " <esc>i")
set("i", "<M-k>", "<esc>v" .. k .. " <esc>i")

set("n", "<M-j>", "v" .. j .. " <esc>h")
set("n", "<M-k>", "v" .. k .. " <esc>h")

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
