vim.keymap.set("n", "<leader>ngc", function()
	require("ertu.ng-utils.create_comp")()
end)
vim.keymap.set("n", "<leader>ngi", function()
	require("ertu.ng-utils.go_to_thing")("imports")()
end)
vim.keymap.set("n", "<leader>ngp", function()
	require("ertu.ng-utils.go_to_thing")("providers")()
end)
