require("ertu")

-- Global
P = function (v)
   print(vim.inspect(v))
   return v
end

local vimrc = vim.fn.stdpath("config") .. "/vimrc.vim"
vim.cmd("source " .. vimrc)


