return {
	"tpope/vim-surround",
	init = function()
		vim.cmd([[
      autocmd FileType typescript,typescriptreact
      \ let b:surround_99 = "{/* \r */}" |
      \ let b:surround_109 = "$Maybe<\r>" | 

    ]])
	end,
	config = function()
		local surroundGroup = vim.api.nvim_create_augroup("Surround group", { clear = true })

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "typescript", "typescriptreact" },
			callback = function()
				vim.keymap.set("n", "<leader>tm", "viwSm", {
					remap = true,
				})
			end,
			group = surroundGroup,
		})
	end,
}
