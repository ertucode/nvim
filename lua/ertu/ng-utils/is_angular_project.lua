return function()
	-- local filename = vim.fn.expand("%:p")
	return vim.fn.filereadable("angular.json") == 1
end
