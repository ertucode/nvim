local create_comp = require("ertu.ng-utils.create_comp")
local go_to_import = require("ertu.ng-utils.go_to_import")

vim.keymap.set("n", "<leader>ngc", create_comp)
vim.keymap.set("n", "<leader>ngi", go_to_import)
