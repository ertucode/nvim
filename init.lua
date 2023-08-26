require("ertu")

-- Global
P = function(v)
	print(vim.inspect(v))
	return v
end

RELOAD = function(...)
	return require("plenary.reload").reload_module(...)
end

R = function(name)
	RELOAD(name)
	return require(name)
end

local vimrc = vim.fn.stdpath("config") .. "/vimrc.vim"
vim.cmd("source " .. vimrc)

vim.keymap.set("n", "<leader><leader>i", function()
	R("ngserve").serve()
end)
