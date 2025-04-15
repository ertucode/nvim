local my_count = 0

local text = ""

_G.main_func = function()
	my_count = 0
	local new_text = vim.fn.input("Enter text to repeat: ", "console.log('', ##)")
	if new_text == nil then
		return
	end
	if new_text ~= "" then
		text = new_text
	end

	local count = vim.fn.input("Enter count: ", tostring(my_count))
	if count == nil or count == "" then
		my_count = 0
	else
		local numbered = tonumber(count)
		if numbered == nil then
			print("Invalid number")
			return
		end

		my_count = numbered
	end

	vim.go.operatorfunc = "v:lua.callback"
	return "g@l"
end

_G.callback = function()
	local text_to_insert = string.gsub(text, "##", my_count, 1)
	vim.cmd("normal! j")
	vim.api.nvim_put({ text_to_insert }, "l", false, true)
	vim.cmd("normal! k")
	my_count = my_count + 1
end

vim.keymap.set("n", "♥", main_func, { expr = true })
