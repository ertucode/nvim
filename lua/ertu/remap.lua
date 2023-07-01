vim.g.mapleader = " "

local set = vim.keymap.set

set("n", "<leader>pv", vim.cmd.Ex)

-- vs code alt-arrow
set("v", "J", ":m '>+1<CR>gv=gv")
set("v", "K", ":m '<-2<CR>gv=gv")

-- append bottom line to current without moving the cursor
set("n", "J", "mzJ`z")

-- center cursor during jumps
set("n", "<C-d>", "<C-d>zz")
set("n", "<C-u>", "<C-u>zz")
set("n", "n", "nzzzv")
set("n", "N", "Nzzzv")

-- paste and delete without buffer
set("x", "<leader>p", [["_dP]])
set({"n", "v"}, "<leader>d", [["_d]])

set("n", "x", '"_x')

-- system register
set({"n", "v"}, "<leader>y", [["+y]])
set("n", "<leader>Y", [["+Y]])

set("n", "Q", "<nop>")
set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
set("n", "<leader>f", vim.lsp.buf.format)

-- quickfix
set("n", "<C-k>", "<cmd>cnext<CR>zz")
set("n", "<C-j>", "<cmd>cprev<CR>zz")
set("n", "<leader>k", "<cmd>lnext<CR>zz")
set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- change the word on the cursor
set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

set("n", "<leader>vpp", "<cmd>e ~/.config/nvim/lua/ertu/packer.lua<CR>");

set("n", "<leader><leader>", function()
    vim.cmd("so")
end)

-- increment decrement
set("n", "<leader>+", '<C-a>')
set("n", "<leader>-", '<C-x>')

